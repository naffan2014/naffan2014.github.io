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
bash publish-gh-pages.sh
```

脚本会:

1. `bundle exec jekyll build` 生成 `_site/`
2. 若有未提交改动,自动 `git add -A` 并提交到 `docs`
3. 用 `git subtree` 把 `_site/` 内容推送到 `origin/master`
4. 清理本地 `_site/`

注意必须用 `bash` 而不是 `sh` 执行,因为脚本用了 `set -o pipefail`。



