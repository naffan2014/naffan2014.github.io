[拿饭的博客](http://naffan.cn)
============

拿饭是由jekyll静态网页技术配合着Herring Cove主题以及Bootstrap配合搭建的响应式博客。


### 博客包括 

* 文章列表，本站点的所有文章。
* 生活闲杂，单独将生活拎成一个版块。
* 经济杂谈，分享自己以及朋友对当前中国经济的分析
* 精彩连接，分享自己收藏的比较不错的站点。
* 阅读书籍，分享自己阅读书籍后的观后感。
* 关于本人，向大家介绍一下自己。

### 站点截图 version 1.4

* 调整部分页面的UI和样式

### 站点截图 version 1.3

* 分类中实现分页功能
* 支持了手动指定作者
* 支持了手动指定首页头图为最新文章的图片
* 支持了阅读书籍栏目手动指定书籍封面

### 站点截图 version 1.2

* 增加又拍云CDN,解决搜索引擎蜘蛛被github屏蔽问题
* 支持在github-pages上部署插件
* 暂时停用图片的延迟加载

### 站点截图 version 1.1

* 支持在github-pages上部署插件
* 增加图片的延迟加载
* 增加SEO
* 增加sitemap.xml
* 增加category的列表
* 更换微博评论箱为畅言
* 增加百度分享插件


### 站点截图 version 1.0

![screenshot](http://ww4.sinaimg.cn/large/73b41ab2jw1f8724mnmuej20yx1jqtsg.jpg)

* 初始化网站
* 内容页框架完成
* 首页头图浮层适应移动设备
* 列表页增加分页
* 模板使用范围设置完成
* 支持微博评论箱
* 增加微博小插件


### 本地预览

仓库使用双分支结构:`docs` 为源码分支,`master` 为 GitHub Pages 静态产物分支。

#### 方式一:Docker(推荐,换电脑零配置)

只需安装 Docker,无需关心 Ruby/Jekyll 版本。镜像已发布到 Docker Hub: [`naffan2015/naffan-jekyll`](https://hub.docker.com/r/naffan2015/naffan-jekyll)。

##### 1. 安装 Docker

| 系统 | 安装方式 |
|---|---|
| **macOS** | 下载 [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/) → 安装后启动 Docker Desktop(菜单栏出现鲸鱼图标) |
| **Windows** | 下载 [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/) → 安装后启动 Docker Desktop |
| **Linux** | `curl -fsSL https://get.docker.com \| sh` 然后执行 `sudo systemctl start docker` |

验证安装:

```bash
docker --version
docker compose version
```

##### 2. 国内网络配置(可选,但推荐)

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

##### 3. 启动预览

```bash
git clone git@github.com:naffan2014/naffan2014.github.io.git
cd naffan2014.github.io
git checkout docs

# 启动本地预览,访问 http://localhost:4000
docker compose up
```

首次会从 Docker Hub 拉镜像(约 300MB,几分钟),之后秒启。文件改动会自动重建并刷新浏览器(已启用 livereload)。

> 如果改了 Dockerfile 或 Gemfile,需要重建镜像:`docker compose up --build`

##### 4. 停止预览

在运行 `docker compose up` 的终端按 `Ctrl+C`,或另开终端执行 `docker compose down`。

#### 方式二:本地 Ruby 环境

不想用 Docker 也可以直接装 Ruby:

```bash
# 切到 docs 分支
git checkout docs

# 安装依赖(首次或 Gemfile 变更后)
bundle install

# 启动本地预览,访问 http://127.0.0.1:4000
bundle exec jekyll serve
```

> 要求 Ruby 3.x+(已在 Ruby 4.0 + Jekyll 4.4 上验证)。

### 发布到 GitHub Pages

写完文章、提交到 `docs` 后,执行:

```bash
# Docker 方式
docker compose run --rm publish

# 或本地 Ruby 方式
bash publish-gh-pages.sh
```

脚本会:

1. `bundle exec jekyll build` 生成 `_site/`
2. 若有未提交改动,自动 `git add -A` 并提交到 `docs`
3. 用 `git subtree` 把 `_site/` 内容推送到 `origin/master`
4. 清理本地 `_site/`

注意必须用 `bash` 而不是 `sh` 执行,因为脚本用了 `set -o pipefail`。

### 更新 Docker 镜像

当修改了 `Dockerfile`、`Gemfile` 或 Ruby 版本时,需要重新构建并推送到 Docker Hub:

```bash
# 登录(首次)
docker login -u naffan2015

# 构建并推送
bash docker-push.sh
```



