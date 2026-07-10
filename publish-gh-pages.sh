#!/bin/bash
# 发布脚本:在 docs 分支构建 _site,推送到 origin/master (GitHub Pages)
# 用法: sh publish-gh-pages.sh [master]
# 用 git subtree 替代旧的 filter-branch,避免强推所有分支和删除本地 master。

set -euo pipefail

BRANCH="${1:-master}"
SOURCE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# 1. 构建(先清理 _site 内容和缓存,避免残留导致偶发 ENOENT)
# 注意:不删 _site 目录本身——publish 容器里它是匿名卷挂载点,删挂载点会报
# "Device or resource busy"。只清空其内容即可。
echo ">> jekyll build"
rm -rf .jekyll-cache .jekyll-metadata
find _site -mindepth 1 -delete 2>/dev/null || true
if [ -f Gemfile ]; then
  bundle exec jekyll build
else
  jekyll build
fi

if [ ! -d "_site" ] || [ -z "$(ls -A _site 2>/dev/null)" ]; then
  echo "!! _site 为空或不存在,终止"
  exit 1
fi

# 2. 提交 docs 上的源码改动(包含新文件)
if ! (git diff --quiet && git diff --cached --quiet); then
  echo ">> 检测到未提交改动,先提交 docs"
  git add -A
  git commit -m "chore: commit before publish at $(date -u +%FT%TZ)"
else
  echo ">> 无未提交改动"
fi

# 3. 把 _site 内容推到 origin/$BRANCH
# _site 在 .gitignore 里,git subtree split 看不到工作区改动。
# 改用临时索引 + work-tree=_site 的方式:
#   - 用独立索引文件,避免污染 docs 分支的索引
#   - 把 _site 当作 work-tree,add 全部内容(根级文件就是 _site 里的文件)
#   - 用 commit-tree 创建 commit,parent 指向 origin/$BRANCH
#   - 推到 origin/$BRANCH
echo ">> 推送 _site 到 origin/$BRANCH"
REMOTE_SHA="$(git rev-parse origin/$BRANCH 2>/dev/null || true)"
TMP_INDEX="$(mktemp)"
trap 'rm -f "$TMP_INDEX"' EXIT

# 在独立索引里,把 _site 目录作为根 add 进来
GIT_INDEX_FILE="$TMP_INDEX" git --work-tree="_site" add -A
TREE_SHA="$(GIT_INDEX_FILE="$TMP_INDEX" git write-tree)"
if [ -z "$TREE_SHA" ]; then
  echo "!! 构建提交树失败,终止"
  exit 1
fi

COMMIT_MSG="publish _site at $(date -u +%FT%TZ) from docs@$(git rev-parse --short HEAD)"
if [ -n "$REMOTE_SHA" ]; then
  NEW_SHA="$(git commit-tree "$TREE_SHA" -p "$REMOTE_SHA" -m "$COMMIT_MSG")"
else
  NEW_SHA="$(git commit-tree "$TREE_SHA" -m "$COMMIT_MSG")"
fi

echo ">> 新 commit: $NEW_SHA (parent: ${REMOTE_SHA:-<none>})"
if ! git push origin "$NEW_SHA:$BRANCH"; then
  echo ">> 普通推送失败(可能是历史不一致),改用强推"
  git push --force origin "$NEW_SHA:$BRANCH"
fi

# 4. 清理本地构建产物(只清空内容,保留目录——匿名卷挂载点不能删)
find _site -mindepth 1 -delete 2>/dev/null || true

echo ">> 完成。当前分支: $(git rev-parse --abbrev-ref HEAD)"
