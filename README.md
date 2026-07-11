# 拿饭网

> 一个属于自己的博客网站 — [https://naffan.cn](https://naffan.cn)

基于 Jekyll + [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) 主题的静态博客,部署在 GitHub Pages。

## 内容板块

- **技术总结** — 后端开发、Java、Spring、硬件折腾
- **生活闲杂** — 日常生活、旅行见闻
- **沈思默想** — 个人思考、读书感悟
- **经济杂谈** — 经济观察、市场观点
- **阅读书籍** — 读书笔记、书评

## 技术栈

| 组件 | 说明 |
|---|---|
| 静态生成器 | [Jekyll](https://jekyllrb.com/) 4.4 |
| 主题 | [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) 7.6(暗黑模式、TOC、搜索、SEO、PWA 全套) |
| 评论 | [Giscus](https://giscus.app)(基于 GitHub Discussions) |
| 容器化 | Docker + Docker Compose |
| 部署 | GitHub Pages(`docs` 源码 → `master` 产物) |

## 本地预览

仓库使用双分支结构:`docs` 为源码分支,`master` 为 GitHub Pages 静态产物分支。

### 方式一:Docker(推荐,换电脑零配置)

只需安装 Docker,无需关心 Ruby/Jekyll 版本。镜像已发布到 Docker Hub: [`naffan2015/naffan-jekyll`](https://hub.docker.com/r/naffan2015/naffan-jekyll)。

#### 1. 安装 Docker

| 系统 | 安装方式 |
|---|---|
| **macOS** | 下载 [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/) → 安装后启动 Docker Desktop |
| **Windows** | 下载 [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/) |
| **Linux** | `curl -fsSL https://get.docker.com \| sh` 然后 `sudo systemctl start docker` |

验证安装:

```bash
docker --version
docker compose version
```

#### 2. 国内网络配置(可选,但推荐)

国内拉镜像慢或失败时,在 Docker Desktop → Settings → Docker Engine 里加镜像加速器:

```json
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.m.daocloud.io"
  ]
}
```

点 Apply & Restart。

#### 3. 启动预览

```bash
git clone git@github.com:naffan2014/naffan2014.github.io.git
cd naffan2014.github.io
git checkout docs

# 启动本地预览,访问 http://localhost:4000
docker compose up
```

首次会从 Docker Hub 拉镜像,之后秒启。文件改动会自动重建并刷新浏览器(已启用 livereload)。

> 如果改了 Dockerfile 或 Gemfile,需要重建镜像:`docker compose up --build`

#### 4. 停止预览

在运行 `docker compose up` 的终端按 `Ctrl+C`,或另开终端执行 `docker compose down`。

### 方式二:本地 Ruby 环境

不想用 Docker 也可以直接装 Ruby:

```bash
git checkout docs
bundle install
bundle exec jekyll serve
```

> 要求 Ruby 3.x+。

## 发布到 GitHub Pages

写完文章、提交到 `docs` 后,执行:

```bash
# Docker 方式(同时推送 GitHub master + 同步又拍云)
docker compose run --rm \
  -e UPYUN_BUCKET=naffanwpstorage \
  -e UPYUN_OPERATOR=naffan \
  -e UPYUN_PASSWORD=你的密码 \
  publish

# 或本地 Ruby 方式
bash publish-gh-pages.sh
```

脚本会:

1. `bundle exec jekyll build` 生成 `_site/`
2. 若有未提交改动,自动 `git add -A` 并提交到 `docs`
3. 用 `GIT_INDEX_FILE + work-tree=_site + commit-tree` 方式把 `_site/` 内容推送到 `origin/master`
4. 调用 `upx sync` 把 `_site/` 同步到又拍云对象存储(回源域名 `naffan.cn`)
5. 清理本地 `_site/`

### 为什么要传 `-e UPYUN_*` 环境变量?

`publish-gh-pages.sh` 内置了 `sync_to_upyun` 函数,在 GitHub 推送完成后会把 `_site/` 全量同步到又拍云对象存储,作为 CDN 回源源站。又拍云的 `upx` CLI 通过三个环境变量鉴权:

| 环境变量 | 含义 | 示例 |
|---|---|---|
| `UPYUN_BUCKET` | 对象存储服务名 | `naffanwpstorage` |
| `UPYUN_OPERATOR` | 操作员账号 | `naffan` |
| `UPYUN_PASSWORD` | 操作员密码 | (在又拍云控制台创建) |

> **为什么不写进 `.env`?** `.env` 已被 `.gitignore` 排除,适合本地保留长期凭据;但 `docker compose run` 默认不读 `.env`(只 `up` 时读),所以发布时显式 `-e` 传参更安全——密码不会留在 shell history 之外。

> **为什么不用 HTTPS+osxkeychain?** 容器里没有 `credential-osxkeychain` helper,所以 GitHub 推送走 SSH remote,又拍云走环境变量,凭据不落盘。

> 注意必须用 `bash` 而不是 `sh` 执行(本地 Ruby 方式),因为脚本用了 `set -o pipefail`。

## 更新 Docker 镜像

当修改了 `Dockerfile`、`Gemfile` 或 Ruby 版本时,需要重新构建并推送到 Docker Hub:

```bash
docker login -u naffan2015
docker compose build serve
docker push naffan2015/naffan-jekyll:latest
```

## 目录结构

```
.
├── _config.yml          # Jekyll 配置(主题、评论、SEO、分页等)
├── _data/               # 侧边栏联系人、分享按钮数据
│   ├── contact.yml
│   └── share.yml
├── _plugins/            # 自定义插件(Chirpy 的 lastmod hook)
├── _posts/              # 博客文章(Markdown)
├── _tabs/               # 顶部导航页(关于、归档、分类、标签)
├── images/              # 站点图片资源
├── tools/               # 一次性迁移脚本(不参与构建)
├── Dockerfile           # Docker 构建文件
├── docker-compose.yml   # serve/build/publish 三服务
├── Gemfile              # Ruby 依赖
├── publish-gh-pages.sh  # 发布脚本
└── index.html           # 首页(使用 Chirpy home 布局)
```

## 主题迁移说明(2026-07)

从旧的 Herring Cove + Bootstrap 3 主题迁移到 Chirpy 7.6。迁移内容包括:

- 69 篇文章 front matter 批量改造(`category` → `categories`、`tag` → `tags`、`cover` → `image`)
- 124 个 `{% img %}` 自定义标签转标准 Markdown 图片语法
- 删除百度分享(已停服)、畅言评论、jQuery lazyload、PlantUML、ECharts 等过时组件
- 旧 URL(`/tech/2022/02/22/1.html`)通过 `jekyll-redirect-from` 自动 301 重定向到新 URL(`/posts/2022-02-22-1/`)
- Giscus 评论系统(需在 `_config.yml` 填入 `repo_id` 和 `category_id` 后启用)

迁移脚本保留在 `tools/` 目录下,仅供参考。
