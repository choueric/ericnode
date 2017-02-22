---
title: Linux内核编译中build目录设置
author: zhs
type: post
date: 2014-02-19T15:22:44+00:00
views:
  - 1858
categories:
  - tech
tags:
  - linux
  - kernel

---

最近在分析yocto中名为poky的嵌入式自动构建系统。在对内核进行定制的时候，看到了一个在进行内核编译时挺有用的特性，之前（作为野生程序员的我）一直没有发现。

该特性就是将源码与编译工作目录分离。其实在很多软件源码编译时都用到了该特性。这个特性好处是，一方面将源码和中间文件、最终文件分离，能够保持源码目录的简洁，理清编译过程；另一方面，可以针对同一份源码使用不同的build目录，每个目录使用不同的配置方法，相互之间不会混淆。

<!--more-->

在内核源码树根目录下的Makefile中，其实已经给出了使用方法。Makefile中相关的注释如下所示：

```c
# kbuild supports saving output files in a separate directory.
# To locate output files in a separate directory two syntaxes are supported.
# In both cases the working directory must be the root of the kernel src.
# 1) O=
# Use "make O=dir/to/store/output/files/"
#
# 2) Set KBUILD_OUTPUT
# Set the environment variable KBUILD_OUTPUT to point to the directory
# where the output files shall be placed.
# export KBUILD_OUTPUT=dir/to/store/output/files/
# make
#
# The O= assignment takes precedence over the KBUILD_OUTPUT environment
# variable.
```

设置build目录的方法有两种

- make时使用O=参数
- 使用环境变量KBUILD_OUTPUT指定

前者会覆盖后者的值。

=============================================================================

以3.12编译为例，编译步骤如下：

```sh
# cd $KERNEL_ROOT && mkdir build
# make O=./build menuconfig
# cd build && mkdir mod
# make
# make modules_install INSTALL_MOD_PATH="./mod"
```

创建编译目录build之后，进行内核配置。make命令之后，就可以在build目录下看到vmlinux，即为内核镜像。make modules\_install命令将驱动模块安装到INSTALL\_MOD_PATH参数指定的目录中。

=============================================================================

除了以上的步骤之外，还有一个更为灵活的编译方式：

```sh
# cd $KERNEL_ROOT && mkdir build
# sh scripts/mkmakefile `pwd` `pwd`/build 3 12
# cd build
# make menuconfig
# make
```

和上面方法的差别是，本方法没有采用make O=xxx命令，而直接提取该命令中真正和创建output目录有关的脚本scripts/mkmakefile，使用该脚本在build目录内创建了一个新的Makefile。

mkmakefile脚本使用四个参数，第一个为内核源码目录，第二个为编译输出目录，第三个为版本，第四个为patchlevel。后两者查看根Makefile的头两行就知道了，也就是内核版本的主、次版本号。mkmakefile脚本中有简要的注释说明。

在根目录的Makefile中，搜索outputmakefile，可以看到这些内容：

```makefile
PHONY += outputmakefile
# outputmakefile generates a Makefile in the output directory, if using a
# separate output directory. This allows convenient use of make in the
# output directory.
outputmakefile:
ifneq ($(KBUILD_SRC),)
	$(Q)ln -fsn $(srctree) source
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/mkmakefile \
	    $(srctree) $(objtree) $(VERSION) $(PATCHLEVEL)
endif
```

可以确认mkmakefile的作用以及用法。

在build目录创建了Makefile之后，在该目录中就像在内核树根目录中那样，可以进行编译相关工作。

最后，虽然做了这么多年内核开发，也号称比较了解，不过却也认识到其实对内核这块不知道的确实也挺多，至少没有完整的看过根Makefile。原因的话，可能和没有系统地读过内核开发相关的官方文档有关系吧，毕竟对英文还是觉得有些难度，需要加油！

===========================================================================

__更新：__

在意识到对内核了解不够之后，我去读了一下内核树根目录下的README，发现以上所总结的东西都是在制造轮子而已。。。在README中对应的文字如下：

```text
BUILD directory for the kernel:

   When compiling the kernel, all output files will per default be
   stored together with the kernel source code.
   Using the option "make O=output/dir" allow you to specify an alternate
   place for the output files (including .config).
   Example:

     kernel source code: /usr/src/linux-3.X
     build directory:    /home/name/build/kernel

   To configure and build the kernel, use:

     cd /usr/src/linux-3.X
     make O=/home/name/build/kernel menuconfig
     make O=/home/name/build/kernel
     sudo make O=/home/name/build/kernel modules_install install

   Please note: If the &#039;O=output/dir&#039; option is used, then it must be
   used for all invocations of make.
```
