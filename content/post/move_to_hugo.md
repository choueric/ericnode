+++
date = "2017-02-22T14:43:32+08:00"
title = "将博客迁移至hugo"
description = "transfer blog to Hugo"
categories = ["tech"]
tags = ["hugo", "blog"]

[blackfriday]
  extensions = ["joinLines"]
+++

# 搭建

最近我用的linode发布了新的[套餐][1]，里面包含了每月$5的最便宜的配置，因此将套餐
换成这个，节约一些资金，毕竟自己的VPS用的服务也不多，不需要很强的性能。而为了更
节省系统资源，准备将wordpress搭的博客迁移到了[hugo][2]。

关于使用hugo的优点介绍和搭建方法，它的官方上也有很多[文章][3]。而我选择用hugo，
主要有以下原因:

- 部署简单
- 网站访问速度快
- Go写的，修改容易
- 文档为Markdown格式
- 离线编写，实时查看效果
- 很多现有主题选择，且修改容易
- 静态网站，不用数据库和apache等大软件

搭建的过程挺简单的，基本步骤如下:

1.  `$ hugo new site <site-name>`: 在同目录下创建一个站点。
2.  `$ hugo new post/<post-name.md>`: 创建一个新文章，写入一些示例文字。
3.  `$ mkdir themes && cd themes && git clone <theme-name-git>`: 添加一个主题。
4.  `$ cd .. && $ hugo server -t <theme-name> -w --buildDrafts`: 启动服务。

在服务启动之后，默认配置下，就可以在`http://localhost:1313`里看到了。

# 主题

hugo已经有很多主题了，在[这里][11]可以看到。我选的主题是[mainroad][4]，不过看了
其他一些主题之后，觉得有一些不满意的地方，于是fork出来，自己做了一些修改:

- 在文章列表视图中，每个文章summary后添加readmore。
- 在单个文章视图中，将标签从底部移到顶部。
- 加入代码高亮。
- 在sidebar中加入RSS、Twitter和Github。
- 调整`<code>`的样式，包括背景色、round corner。
- 加入favicon。

可以通过以下命令添加到hugo中:

	git clone https://github.com/choueric/mainroad

# 中文换行问题

在用hugo渲染Markdown的过程中发现，一个段落中行被浏览器显示之后，换行符被替换成
了空格。这样的问题在网上也有很多讨论，例如:

- [解决 jekyll 中文换行变成空格的问题][5]
- [解决 Markdown 转 HTML 中文换行变空格的问题][6]
- [还是中文 README.md 换行变空格的问题][7]

对hugo来说，我觉得比较好的方法还是在将Markdown转换为HTML时，将同一个段落内的行
合并成一行。hugo使用的转换引擎[blackfriday][8]提供了Extension，用户可以通过设置
不同的Extension Options来调整引擎转换的行为。

我添加了一个`JOIN_LINES`的Extension。当文章的front matter中设置了该Extension，
如下所示:

```
[blackfriday]
  extensions = ["joinLines"]
```

那么就会进行合并。虽然提了[Pull request][9]，不过编译之后的版本可以从[这里][10]
下载。

**Update 2017-06-28:**

在blackfriday合并上面的PR之后，我又提交了一个[Pull request][12]给Hugo，以便该
特性能够在Hugo中使用，目前该PR也被合并 :)

# 总结

最后，将整个hugo的目录放到Github上作为一个reposity，然后加上一个Makefile和一些
脚本，让部署和发布更自动一些。然后服务器上添加一个cron任务，每5分钟pull一下，这
样就可以定时更新网站了`^_^`。

不过相比之前使用Wordpress比，还有一些其他虽然不是必须的功能，后续有空再实现:

- [ ] 评论功能，使用disqus。
- [ ] 自动发布到Twitter。


[1]: https://blog.linode.com/2017/02/14/high-memory-instances-and-5-linodes/
[2]: https://gohugo.io/
[3]: https://gohugo.io/community/press/
[4]: https://github.com/vimux/mainroad
[5]: http://blog.guorongfei.com/2015/04/25/how-to-fix-the-markdown-newline-blank-problem/
[6]: http://chenyufei.info/blog/2011-12-23/fix-chinese-newline-becomes-space-in-browser-problem/
[7]: https://github.com/tumashu/chinese-pyim/issues/9
[8]: https://github.com/russross/blackfriday
[9]: https://github.com/russross/blackfriday/pull/334
[10]: /hugo
[11]: http://themes.gohugo.io
[12]: https://github.com/gohugoio/hugo/pull/3574
