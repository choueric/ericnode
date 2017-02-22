---
title: vim中对80字符的限制提示
author: zhs
type: post
date: 2009-09-24T12:01:33+00:00
views:
  - 3362
categories:
  - tech
tags:
  - vim

---

前几天在读mutt的manual的时候，深深的感觉到每行80字符限制的好处。随后想起自己的程序代码从来不曾考虑过这个，汗颜。再说了，在 Delphi里，VC里，编辑区右侧都有那么一个竖线来表示80字符的限制的，虽然不一定要遵守，但是毕竟是一个好习惯。想到自己的vim中是不是也能添上这么一条竖线呢？上网找了一个，相关的只有一个超过80字符会有颜色高亮显示的，但是有一个问题，就是不能在打开每个文件是都能执行，于是找vim的 help了，发现以下在vimrc中添加的命令能够实现

```vim
hi Over80 guifg=fg guibg=Blue
au BufNewFile,BufRead *.* match Over80 '\%>80v.*'
```

第一句是定义了自己的颜色方案，第二句则是在BufNewFile和BufRead事件发生时对于\*.\*的文件执行命令`match Over80 '\%>80v.*'`，这样的话便可以自动执行匹配命令来提醒了。

后来在vim的wiki上搜索80字符限制时（怎么没一早想到这个呢，还在google上搜了那么长时间），发现是有针对该功能的：<a title="http://vim.wikia.com/wiki/Highlight_long_lines" href="http://vim.wikia.com/wiki/Highlight_long_lineshttp://" target="_blank">http://vim.wikia.com/wiki /Highlight_long_lines</a>。看了一下，他的两种方法中居然有一种是和我的山寨方法是一样的。同时他有说了，vim目前还是做不到像 Delphi那样显示一条限制线：Unlike some editors, Vim cannot show a line at this width.

# 后续
 
现在我使用的方式是在配置文件中添加如下语句，这样就只会在右侧显示一条限制线，而不会如同上面的方法一样修改的是文本自身的颜色。该特性是7.3版本中加入，具体可help colorcolumn：

```vim
" 设置超过80长度提示
set colorcolumn=81
```
