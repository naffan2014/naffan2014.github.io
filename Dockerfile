# Jekyll 博客构建/预览镜像(Chirpy 主题)
# 用法见 docker-compose.yml
FROM ruby:3.3-slim

# 换成阿里云 Debian 镜像源(国内访问快)
RUN sed -i 's|deb.debian.org|mirrors.aliyun.com|g; s|security.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources

# 安装 jekyll 依赖的系统包
# - build-essential: 编译 native gem 扩展 (nokogiri/ffi/eventmachine 等)
# - git: publish-gh-pages.sh 发布需要,以及 Chirpy 的 lastmod hook 需要
# - openssh-client: publish 容器走 SSH remote 推送需要 ssh 命令
# - ca-certificates: bundle install 拉 https gems + 又拍云 upx 下载
# - imagemagick: Chirpy 生成文章封面/缩略图需要
# - jq: Chirpy 部署辅助脚本(可选,不影响核心功能)
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      git \
      openssh-client \
      ca-certificates \
      curl \
      imagemagick \
      jq \
    && rm -rf /var/lib/apt/lists/*

# 安装又拍云 upx 命令行工具(publish 时同步 _site 到又拍云对象存储)
# 用国内镜像加速 GitHub release 下载
ARG UPX_VERSION=0.4.9
RUN arch="$(dpkg --print-architecture)" \
    && case "$arch" in \
         amd64) upx_arch="amd64";; \
         arm64) upx_arch="arm64";; \
         *) echo "unsupported arch: $arch" && exit 1;; \
       esac \
    && curl -fL --retry 3 -o /tmp/upx.tar.gz \
         "https://ghfast.top/https://github.com/upyun/upx/releases/download/v${UPX_VERSION}/upx_${UPX_VERSION}_linux_${upx_arch}.tar.gz" \
    && tar -xzf /tmp/upx.tar.gz -C /tmp/ \
    && mv /tmp/upx /usr/local/bin/upx \
    && chmod +x /usr/local/bin/upx \
    && rm -f /tmp/upx.tar.gz \
    && upx version 2>&1 | head -1

# 工作目录
WORKDIR /srv/jekyll

# 先拷贝依赖描述,利用 docker 层缓存
COPY Gemfile Gemfile.lock ./

# 安装 gem 依赖到系统路径(不用 vendor/bundle,避免被宿主机挂载覆盖)
# 用 ruby-china 镜像加速(国内访问 rubygems.org 慢)
RUN gem install bundler -v "$(grep -A1 'BUNDLED WITH' Gemfile.lock | tail -1 | tr -d ' ')" \
    && bundle config set --global mirror.https://rubygems.org https://gems.ruby-china.com \
    && bundle install

# 拷贝项目源码(.dockerignore 会排除 _site 等)
COPY . .

# Jekyll 默认端口
EXPOSE 4000

# 默认启动本地预览服务
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4000"]
