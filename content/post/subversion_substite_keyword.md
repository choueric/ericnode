---
title: subversion内的关键字替换
author: zhs
type: post
date: 2010-04-15T10:27:22+00:00
views:
  - 696
categories:
  - tech
tags:
  - svn
  - linux

---

对于subversion来说，一些版本信息是不需要手动添加的，subversion提供了关键字替换这个功能，用来自动更新一些有用的字 符串，包括：

* Date, LastChangedDate：文件最后一次在版本库修改的日期。
* Revision, Rev, LastChangedRevision：文件最后一次修改的修订版本号。
* Author, LastChangedBy：最后一个修改这个文件的用户。
* HeadURL, URL：这个文件在版本库的完全URL
* Id：是其他关键字的一个压缩组合。

除了在文本中添加相应的关键字之外，例如: `$LastChangedDate $`，你还需要在该文本文件的文件属性里设置，以告知subversion你希望系统替换该关键字。该设置文件的文件属性的命令为：

<!--more-->

`$ svn propset svn:keywords "Date Author" a.c`

这里设置了两个关键字的替换，一个为Date，一个为Author，针对的是文件a.c。 这样在提交属性修改之后，你就可以在文件的关键字位置看到，该关键字已经被扩展为了具体的版本信息字符串。在源码里，可以将这些关键字放在注释里，或者放到打印字符串中，对于了解程序的版本信息十分方便。

不过需要注意的是，关键字&#8221;Rev&#8221;经常会将新用户迷惑。 自从版本库有了单独的全局增长的修订版本号码，许多人认为Rev关键字是放映修订版本号码的，但实际上Rev是含有该关键字的文件最后修改的修订版本，而不是最后更新的，即不是所谓的GlobalRev。

那么为了得到全局修订版本号，subversion 提供了一个工具svnversion。它会遍历你的工作拷贝，然后输出它发现的修订版本。你可以使用这个程序，外加一些工具，将修订版本信息嵌入到你的指定文件中。

下面给出两种方法。两种方法都需要一些共同的准备工作。需要创建一个存放版本信息的文 件，这里为version.h。并且项目的目录结构如下所示：

```text
|-- Makefile
|-- config/
|-- doc/
|-- res/
|-- sh/
`-- src/
|--version.h
|-- ....
`-- Makefile
```

# 方法一

首先在sh目录下创建 一个shell脚本，svnversion.sh，内容如下：

```sh
#!/bin/sh
#自动添加subversion的 全局版本信息
#以及其他需要的信息到指定文件中
#切换为英文语言环境
LANG=en_US.UTF-8
VERFILE=./src/version.h

svn_ver=`svnversion`
svn_date=`date`
sys_info=`uname -rsnm`
sys_user=`whoami`

echo "#define SVNREV \"$svn_ver\"" > $VERFILE
echo "#define SVNUSER \"$sys_user\"" >> $VERFILE
echo "#define SVNDATE \"$svn_date\"" >> $VERFILE
echo "#define SVNINFO \"$sys_info\"" >> $VERFILE
```

执行这个脚本，会将你所想要输出的信息作为字符串宏输出到指 定文件中。为了能够在每次更新版本库后能够自动执行该脚本，以便自动更新版本号信息，还需要修改项目顶层目录下的 Makefile，增加一个目标，如下：

```makefile
up:
    svn up
    ./sh/svnversion.sh
```

这要求以前使用`$svn up`进行update版本库，如今要使用`$make up`来进行。 $make up首先执行svn up，更新版本库，然后执行上述的脚本，将更新后的版本库的相关信息写入到指定文件中。这样便完成了信息更新的自动化，并且版本号是由 svnversion得出的全局版本号。

# 方法二

首先，针对需要记录版本信息的文件 version.h设置好关键字字符串并且使用svn设置好关键字替换属性，如上所述。然后修改顶层的 Makefile文件，添加一个目标，如下：

```makefile
ci:
    echo "#define a" >> ./src/version.h
    svn ci
```

这要求从前使用`$svn ci`进行提交，如今要使用`$make ci`来进行。 $make ci首先添加一行无效的宏定义到指定文件，以便自动对文件进行修改，然后执行提交命令。因为每次提交前都对指定文件进行了自动修改，因此每次提交后都会进行版本信息关键字替换，保持为最新的全局版本号。

两种方法都是 对version.h进行添加版本信息。只要包含version.h即可进行调用。两种方法都是需要用户添加Makefile一个新目标来代 替原来的svn ci或svn up。这个需要用户自己记住。

第一种方法，采取了由用户自己提取信息，然后添加为字 符串宏来进行调用。优点是用户可以添加很多其他信息到文件中；缺点是除了svnversion之外，其他信息的获取都是有用户自 己获取的。

第二种方法，采取了自动修改需要进行关键字替换的文件。优点是使用的是subversion提供的关键字 替换机制；缺点是，每次执行会给指定文件添加额外的无效宏定义，需要用户自己定期删除。

注意，如果要加入关键字替换 字符串以及属性的文件的编码不是UTF-8，则里面的非英文字符可能会被弄成乱码。
