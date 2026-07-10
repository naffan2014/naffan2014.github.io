#!/bin/bash
# 把 naffan-jekyll 镜像推送到 Docker Hub
# 用法: bash docker-push.sh [tag]

set -euo pipefail

IMAGE="naffan2015/naffan-jekyll"
TAG="${1:-latest}"

# 1. 确认已登录
if ! grep -q "https://index.docker.io/v1/" ~/.docker/config.json 2>/dev/null; then
  echo ">> 未检测到 Docker Hub 登录,执行 docker login"
  docker login
fi

# 2. 构建镜像(用 Docker Hub 仓库地址作为 tag)
echo ">> 构建镜像 $IMAGE:$TAG"
docker build -t "$IMAGE:$TAG" .

# 3. 推送镜像
echo ">> 推送镜像到 Docker Hub"
docker push "$IMAGE:$TAG"

# 4. 同步给本地 naffan-jekyll 名字(兼容旧的 docker-compose 引用)
docker tag "$IMAGE:$TAG" naffan-jekyll:latest

# 5. 推送 README 作为 Docker Hub Overview
#    Docker Hub 约定:推一个特殊标签的镜像,标签名固定为 "readme",
#    镜像里根目录的 README.md 会自动同步到仓库 Overview 页
echo ">> 推送 README 到 Docker Hub Overview"
TMP_DOCKERFILE="$(mktemp /tmp/dockerfile.XXXXXX)"
cat > "$TMP_DOCKERFILE" <<'EOF'
FROM scratch
COPY docker-readme.md /README.md
EOF
docker build -t "$IMAGE:readme" -f "$TMP_DOCKERFILE" .
rm -f "$TMP_DOCKERFILE"
docker push "$IMAGE:readme"
docker rmi "$IMAGE:readme" 2>/dev/null || true

echo ""
echo ">> 完成: $IMAGE:$TAG"
echo ">> 换电脑后用 docker pull $IMAGE:$TAG 拉取"
echo ">> Overview 页面: https://hub.docker.com/r/$IMAGE"

