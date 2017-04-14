+++
date = "2017-04-14T13:41:41+08:00"
title = "配置git diff的输出颜色"
description = "配置git diff的输出颜色"
isCJKLanguage = true
categories = ["Tech"]
tags = ["git"]
draft = false

[blackfriday]
  extensions = ["joinLines"]

+++

# 背景

最近需要大量比对之前同事对内核做的修改，用`git show`和`git diff`看各个commit之
间的差异。虽然默认情况下，git配置里已经将color.ui设置为auto，输出已经是有颜色的
了，输出是这样的:

![def_git_show](/colorize_git_diff/def.png)

但是输出信息一多，我觉得文件和文件之间、文件内部的修改和修改之间不能一眼区别出
来，比较费眼睛。所以想着是不是能自己修改一下配色。google了一下，还真有对应的配
置。

# 配置说明

执行`$ git help config`，在里面搜找`color.diff`，有以下几个相关配置的说明: 

```text
color.diff
    Whether to use ANSI escape sequences to add color to patches. If this is set to always, git-diff(1), git-log(1), and git-show(1) will use color for all patches. If it is set to true or auto, those commands will only use color when output is to the terminal. Defaults to false.

    This does not affect git-format-patch(1) nor the git-diff-* plumbing commands. Can be overridden on the command line with the --color[=<when>] option.

color.diff.<slot>
    Use customized color for diff colorization.  <slot> specifies which part of the patch to use the specified color, and is one of plain (context text), meta (metainformation), frag (hunk header), func (function in hunk header), old (removed lines), new (added lines), commit (commit headers), or whitespace (highlighting whitespace errors). The values of these variables may be specified as in color.branch.<slot>.
	
color.branch.<slot>
    Use customized color for branch coloration.  <slot> is one of current (the current branch), local (a local branch), remote (a remote-tracking branch in refs/remotes/), upstream (upstream tracking branch), plain (other refs).

    The value for these configuration variables is a list of colors (at most two) and attributes (at most one), separated by spaces. The colors accepted are normal, black, red, green, yellow, blue, magenta, cyan and white; the attributes are bold, dim, ul, blink and reverse. The first color given is the foreground; the second is the background. The position of the attribute, if any, doesn’t matter.
```

`color.diff`说明这些设置会影响`git diff`, `git log`和`git show`命令。

`color.diff.<slot>`则定义了slot，以及可设置的值:

- plain
- meta
- frag
- func
- old
- new
- commit
- whitespace

`color.branch.<slot>`则说明了配色的设置方式，包括最多两个颜色和最多一个属性，用
空格分开。第一个颜色是前景色，第二个颜色是背景色，取值包括:

- normal
- black
- red
- green
- yellow
- blue
- magenta
- cyan
- white

而属性的取值包括:

- bold
- dim
- ul
- blink
- reverse

# 修改

根据以上的说明，在配置文件中(一般为`$HOME/.gitconfig`)增加以下配置:

```sh
[color "diff"]
	meta = white reverse
	frag = cyan reverse
	old = red bold
	new = green bold
```

其中修改了四个slot的颜色属性:

- meta: meta information，分割了不同的文件。设置为white reverse。
- frag: hunk header, 文件中一个修改的头，分割了同一个文件内的不同修改。设置为
  cyan reverse。
- old: 被删除的代码，设置为red bold。
- new: 新增的代码，设置为green bold。

出来的效果是这样的:

![after_colorized](/colorize_git_diff/after.png)

这样，不同文件、同一文件中的不同修改块都用了比较明显的背景色，这样就比较容易识
别了。

# 总结

其实从`$ git help config`里可以看到几乎所有元素都有对应的配置选项，你可以根据自
己的需要定制不仅仅是颜色，还包括其他方面的配置，不得不说git真是太强了。
