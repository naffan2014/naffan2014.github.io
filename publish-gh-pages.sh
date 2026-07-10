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

# 3. 用 subtree 把 _site 内容推到 origin/$BRANCH
# 先 split 出 _site 对应的 commit,再 push。历史不一致时用 --force 强推。
echo ">> 推送 _site 到 origin/$BRANCH"
SPLIT_SHA="$(git subtree split --prefix=_site)"
if [ -z "$SPLIT_SHA" ]; then
  echo "!! subtree split 失败,终止"
  exit 1
fi
if ! git push origin "$SPLIT_SHA:$BRANCH"; then
  echo ">> 普通推送失败(可能是历史不一致),改用强推"
  git push --force origin "$SPLIT_SHA:$BRANCH"
fi

# 4. 清理本地构建产物(只清空内容,保留目录——匿名卷挂载点不能删)
find _site -mindepth 1 -delete 2>/dev/null || true

echo ">> 完成。当前分支: $(git rev-parse --abbrev-ref HEAD)"
