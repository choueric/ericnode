---
title: 嵌入式构建系统buildroot的简单介绍
author: zhs
type: post
date: 2015-12-28T08:26:30+00:00
iscjklanguage: true
views:
  - 962
categories:
  - tech
tags:
  - embedded
  - linux
  - buildroot

---

之前在前东家
参与开发的一款产品使用了Intel的SoC，而其官方评估板推荐的测试系统有两个:
yocto和timesys（后来发现这两个都是基于yocto来构建的），因此我们也不得不使用
yocto来构建系统。

Yocto的前身应该是OpenEmbedded，使用bitbake最为核心工具，由bitbake解析包配置
(recipe)、处理包依赖关系并fork任务执行下载、解压、打补丁、编译、安装和制作镜像。
bitbake是python写的。Yocto是用来直接构建一个发行版重量级系统，还能够生成包管理
系统来支持在线安装。

<!--more-->

一开始我觉得这东西简直太牛了，有了它，大部分以前头疼的工作都帮你做了，
你只需要配置一下参数即可，执行编译你就能得到一个系统镜像，dd到优盘，
就得到了一个安装盘！但是惊喜也只是一小会儿，随着后续的开发，
发现了很多Yocto使用上的不便：

- 占用磁盘空间大，python程序执行效率低，编译时间长，不利于修改后查看效果
- 不方便引用外部交叉工具链
- 虽然文档篇幅很多，但因为yocto过于复杂很多细节问题没有涉及或表述不清楚、不充分，
  导致很多问题都需要自己看代码了解或者hack
- 规模太大，不能脉络清晰的了解框架，添加和修改软件包往往不是很优雅，导致越做越恶心

其实这些缺点归根结底，还是因为Yocto过于复杂，想要顾及到方方面面，
导致不管是写文档来描述还是实际动手定制，都十分令人沮丧。

而buildroot作为面向嵌入式的构建系统，让我这个被Yocto恶心过的人用起来觉得如沐春
风、有的放矢。

buildroot麻雀虽小但五脏俱全，该有的重要功能一样也不少：

- 自带丰富的软件包配置和补丁
- 使用Linux kernel的Kconfig机制，能够使用menuconfig进行配置
- 下载、解压、补丁、编译、安装
- 特别支持linux kernel、busybox，能够单独使用menuconfig
- 能方便外部交叉工具链
- 使用Makefile语法，系统构建速度快
- 舍弃编译过程中的包依赖关系，没有复杂的抽象，代码结构清晰，便于增减和定制
- 针对嵌入式，提供很多细节的配置

以上只是我个人使用后的感受，觉得在中小型嵌入式系统构建上来说，buildroot完胜Yocto。
而即便是大型系统，Yocto是否有十分好用呢？我持怀疑态度。因为最最重要的一点在于，
开发过程你不能指望将构建系统下载下来，经过简单配置然后编译，就能满足产品要求了。
开发过程中，因为各种各样的原因，一定会需要你去修改和定制构建系统。而Yocto这种代
码复杂、抽象层次和概念多、文档不清晰、编译时间长的系统，觉得是每个人的噩梦。

说了这么多，下面简要介绍一下buildroot的使用，这里使用的buildroot版本为2015.08.1。

从官网上下载下来之后，首先查看docs/manual/manual.pdf文档，该文档由浅入深、从整
体到细节的介绍了buildroot，后续开发过程中还可以会过头再查找相关细节。通过该文
档，了解了buildroot构建系统中的概念后，基本上就可以直接上手了。

```text
make help                // 查看编译命令的帮助说明
make menuconfig          // 配置构建系统，包括平台属性、指定内核和uboot等
make linux-menuconfig    // 调用内核的menuconfig
make busybox-menuconfig  // 调用busybox的menuconfig
make <package-name>;     // 单独构建package
make                     // 开始构建整个系统
```

其中，make menuconfig可以用来配置构建系统，直接拷贝Linux内核的那套工具（打了些
patch），可以进行内核代码路径、目标平台架构、交叉编译链、生成文件系统镜像格式等
配置，非常简洁方便，比Yocto不知道高到哪里去了。

添加软件包也非常方便，具体可以参考manual
`Chapter 17 Adding new packages to Buildroot`，详细介绍了相关的各种方法和变量。
这里举个栗子，说明一下buildroot对于嵌入式开发的友好。

嵌入式中往往会写自己的驱动模块，编译成ko文件，然后在内核启动之后，根据实际的要
求再动态的加载。在manual的`Chapter 17.14 Infrastructure for packages building kernel`
中，说明了如何向板卡中加入一个自己的内核驱动模块。这里是示例的配置文件：

```makefile
#################################################################
# foobar driver
# refer to buildroot manual chapter 17.14
#################################################################

FOOBAR_VERSION = 1
FOOBAR_SITE_METHOD = local
FOOBAR_SITE = $(TOPDIR)/$(call qstrip,$(BR2_PACKEG_FOOBAR_SRCPATH))
FOOBAR_INSTALL_IMAGES = NO
FOOBAR_INSTALL_TARGET = YES

FOOBAR_MODULE_SUBDIRS=src
FOOBAR_CFG_DIR=$(TARGET_DIR)/etc/modprobe.d

define FOOBAR_INSTALL_TARGET_CMDS
	install -d $(FOOBAR_CFG_DIR)
	install -m 644 $(@D)/foobar.conf $(FOOBAR_CFG_DIR)
endef

$(eval $(kernel-module))
$(eval $(generic-package))
```

在该配置的最下面两行，表明了所使用的模板：

- generic-package添加了通用的包所支持的变量和操作
- kernel-module则添加了内核模块所特有的变量和操作

有了这两个模板，只需要简单配置就可以了：

- `FOOBAR_SITE_METHOD`指定源码为本地
- `FOOBAR_SITE`指定包路径，`BR2_PACKEG_FOOBAR_SRCPATH`包含的为相对路径
- `FOOBAR_MODULE_SUBDIRS`指定源码包中实际代码子目录

在编译过程中，内核源码树KERDIR、交叉工具CROSS_COMPILE以及平台ARCH都由buildroot
处理；编译完成之后，自动将模块文件安装在/lib/modules对应内核版本目录下，并更新
depmod缓存。

如果你需要安装额外的文件，如上面将foobar.conf安装到/etc/modprobe.d目录中，
只需要定义`FOOBAR_INSTALL_TARGET_CMDS`，加入对应的安装shell命令，即可添加额外的安装
命令了。

此外，因为buildroot自身编译迅速、定制性高的缘故，即便不用来构建整个系统，
而是作为交叉编译平台，编译一两个工具软件放到板子上执行，也是非常便利的。

本文就只简单地介绍了这一个例子，因为manual文档的详细和buildroot自身的简洁清晰，
buildroot的使用者能够很快上手，即便碰到问题，凭借着使用shell和内核Kconfig的经验，
也能很快定位问题和解决问题。
