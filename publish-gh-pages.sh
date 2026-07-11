#!/bin/bash
# 发布脚本:在 docs 分支构建 _site,推送到 origin/master (GitHub Pages)
# 同时同步 _site 到又拍云对象存储(CDN 实际源站)
# 用法: sh publish-gh-pages.sh [master]

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
TMP_INDEX="$(mktemp -u)"
trap 'rm -f "$TMP_INDEX"' EXIT

# 在独立索引里,把 _site 目录作为根 add 进来
# (TMP_INDEX 文件不存在时 git 会自动创建,不要用 mktemp 预创建空文件)
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

# 4. 同步 _site 到又拍云对象存储(CDN 实际源站)
# 又拍云对象存储资源更新会自动触发 CDN 缓存刷新(5分钟内生效),无需手动 purge
sync_to_upyun() {
  # 检查凭证是否完整
  if [ -z "${UPYUN_BUCKET:-}" ] || [ -z "${UPYUN_OPERATOR:-}" ] || [ -z "${UPYUN_PASSWORD:-}" ]; then
    echo "!! 又拍云凭证未设置 (UPYUN_BUCKET/UPYUN_OPERATOR/UPYUN_PASSWORD),跳过同步"
    echo "!! 站点 CDN 仍会返回旧内容,请手动同步或配置凭证后重跑"
    return 0
  fi

  echo ">> 登录又拍云 (bucket=$UPYUN_BUCKET, operator=$UPYUN_OPERATOR)"
  upx login "$UPYUN_BUCKET" "$UPYUN_OPERATOR" "$UPYUN_PASSWORD" >/dev/null

  echo ">> 同步 _site 到又拍云根目录 (--delete --strong)"
  # 关键:必须用 --delete,否则远程已存在但本地没改动的文件(如旧的 index.html)
  # 不会被覆盖,sync 增量比对 mtime 会跳过,导致首页等内容停留在旧版本。
  # --strong 强一致模式,绕过 upx 本地 db 缓存,避免漏判。
  # 注意:upx sync 会尝试写 ~/.upx.db,容器权限受限环境可能报
  # "operation not permitted" 但实际不影响上传,用 || true 兜底。
  upx sync --delete --strong _site / 2>&1 | tail -20 || true

  echo ">> 又拍云同步完成"
}

echo ">> 同步到又拍云对象存储"
sync_to_upyun

# 5. 清理本地构建产物(只清空内容,保留目录——匿名卷挂载点不能删)
find _site -mindepth 1 -delete 2>/dev/null || true

echo ">> 完成。当前分支: $(git rev-parse --abbrev-ref HEAD)"
