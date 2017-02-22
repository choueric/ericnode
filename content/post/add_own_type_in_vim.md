---
title: 在vim中添加自己的文件类型
author: zhs
type: post
date: 2013-10-07T04:00:52+00:00
views:
  - 1183
categories:
  - tech
tags:
  - vim

---

这里仅仅是举一个简单的栗子，说明如何在vim中添加自己的文件类型，因为vim会针对不同的文件类型套用不同的语法高亮、执行不同的初始动作等。这里以添加*.z类型文件并配以自定义的语法高亮来显示效果。

1. 首先，在~/.vim/syntax/下建立z.vim，保存的是语法高亮的内容，这边借用的是c.vim；
2. 然后在~/.vim/ftdetect/下加入z.vim，添加： `au BufRead,BufNewFile *.z set filetype=z`，用来探测未定义的文件类型，并执行z.vim内定义的动作 
3. 添加set ai和set formatoptions=tcrqn，这个针对z类型设定自动缩进和注释的格式，formatoptions的相关设定可以help formatoptions.
