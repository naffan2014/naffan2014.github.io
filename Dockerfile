# Jekyll 博客构建/预览镜像
# 用法见 docker-compose.yml
FROM ruby:3.3-slim

# 换成阿里云 Debian 镜像源(国内访问快)
RUN sed -i 's|deb.debian.org|mirrors.aliyun.com|g; s|security.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources

# 安装 jekyll 依赖的系统包
# - build-essential: 编译 native gem 扩展 (nokogiri/ffi/eventmachine 等)
# - git: subtree split 发布需要
# - ca-certificates: bundle install 拉 https gems
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      git \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

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
