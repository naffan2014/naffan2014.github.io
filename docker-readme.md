# naffan-jekyll

[![Jekyll](https://img.shields.io/badge/Jekyll-4.4.1-red.svg)](https://jekyllrb.com/)
[![Ruby](https://img.shields.io/badge/Ruby-3.3-blue.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

> 拿饭网博客系统的 Docker 镜像,封装 Jekyll 4.4 + 所有依赖,用于本地预览和发布到 GitHub Pages。

## 这是什么

这是 [拿饭网](https://naffan.cn) 博客的构建环境镜像。博客源码托管在 [GitHub](https://github.com/naffan2014/naffan2014.github.io),使用 Jekyll 4.4 生成静态站点。

镜像基于 `ruby:3.3-slim`,封装了:

- Ruby 3.3 + Bundler
- Jekyll 4.4.1 及所有插件(jekyll-seo-tag / jekyll-sitemap / jekyll-paginate-v2 / jekyll-feed)
- git(用于 subtree 发布)
- 国内 apt/gem 镜像加速(阿里云 + ruby-china)

## 用途

镜像提供三个场景,通过 docker-compose 编排:

| 场景 | 命令 | 说明 |
|---|---|---|
| **本地预览** | `docker compose up` | 启动 Jekyll serve,访问 http://localhost:4000,支持 livereload |
| **仅构建** | `docker compose run --rm build` | 生成 `_site/` 到当前目录 |
| **发布到 GitHub Pages** | `docker compose run --rm publish` | 构建 + 用 git subtree 推送到 origin/master |

## 快速开始

```bash
# 1. 克隆博客源码
git clone git@github.com:naffan2014/naffan2014.github.io.git
cd naffan2014.github.io
git checkout docs

# 2. 启动本地预览(自动拉取本镜像)
docker compose up

# 3. 浏览器访问 http://localhost:4000
```

只需安装 Docker,无需本地装 Ruby/Jekyll。

## 镜像标签

| 标签 | 说明 |
|---|---|
| `latest` | 最新稳定版,跟 master 分支同步 |
| `x.y.z` | 对应版本号(规划中) |

## 技术栈

- **基础镜像**: `ruby:3.3-slim` (Debian Trixie)
- **博客引擎**: Jekyll 4.4.1
- **主题**: Herring Cove + Bootstrap
- **分页**: jekyll-paginate-v2
- **SEO**: jekyll-seo-tag
- **Sitemap**: jekyll-sitemap
- **Feed**: jekyll-feed

## 相关仓库

- **博客源码**: [naffan2014/naffan2014.github.io](https://github.com/naffan2014/naffan2014.github.io)
- **博客线上**: [https://naffan.cn](https://naffan.cn)

## 许可证

MIT
