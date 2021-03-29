+++
draft = false
date = "2021-03-25T01:13:38+01:00"
title = "使用extlinux引导系统"
description = "how to use extlinux to boot system"
isCJKLanguage = true
categories = ["tech"]
tags = ["linux", "embedded", "syslinux", "extlinux"]

[blackfriday]
extensions = ["joinLines"]

+++

# Intro

前一阵忙的项目是在一个非常非常老的486处理器上用buildroot重新构建一个系统，
以支持最新的内核和工具链。

因为本质上是PC架构，一开始选的bootloader是默认的grub。但实际运行之后，grub在找
到内核并解析执行之后，机器就hang在那里了。因为没有太多对grub的经验和调试手段，
加上项目时间比较紧，果断切换到syslinux and it works！

# 文档

syslinux本身是运行在MS-DOS/Windows FAT文件系统上的。如果是使用ext2/3/4
作为boot分区的文件系统的话，就需要使用extlinux。关于syslinux和extlinux，
官方的wiki是很好的文档: [syslinux wiki][1]和[extlinux wiki][2]。

另外还有Arch wiki上的syslinux页，里面有一段介绍[syslinux的启动过程][3]，写得非
常清楚，推荐阅读。

# buildroot

这里使用的buildroot版本是`2020.11`。

首先在menuconfig中选择syslinux作为bootloader，并勾选"install MRB"。因为是90年代
的平台，只支持传统的BIOS/MRB启动方式。syslinux的版本是`6.03`。

此外，磁盘分区表选择GPT而不是DOS，因此必须使用gptmbr.bin而不是mbr.bin。这个是存
放在磁盘最开始440 byte的boot code，会直接被BIOS调用。gptmbr能够识别GPT分区表，
从而找到boot分区并执行ldlinux.sys。

如何编译buildroot这里不多说，可以参考[嵌入式构建系统buildroot的简单介绍][4].

编译完成后会得到:

- output/images/syslinux/gptmbr.bin
- output/host/sbin/extlinux
- output/images/rootfs.cpio

# 制作系统

完成buildroot编译之后，就可以开始将系统部署在磁盘上了。这里的磁盘是一个CF卡，通
过USB读卡器连接到PC后，识别为`/dev/sda`。

## 分区

首选使用gdisk来划分区，如下面的函数所示:

```sh
create_partitions()
{
  blk="/dev/sda"

  {
    echo o; echo y
    echo n; echo 1; echo 2048; echo +16M; echo 8300
    echo n; echo 2; echo 34816; echo +128M; echo 8300
    echo w; echo y; sleep 1
  } | gdisk "${blk}"

  sgdisk "${block_device}" --attributes=1:set:2; sleep 3

  return $?
}

create_partitions
mkfs.ext4 -F -L boot /dev/sda1
mkfs.ext4 -F -L root /dev/sda2
```

这里划分了两个分区并格式化为ext4:

- boot分区，16MB大小。注意这里start sector是2048，以便有足够的空间来存放gptmbr.bin
- root分区，128MB大小。用来存放rootfs.cpio

## 安装extlinux和内核

接下来安装bootloader。

先使用`dd`将gptmbr.bin从0地址开始写到/dev/sda上。这也是上一节里要空出空间的原因。

```sh
dd if=/path/to/gptmbr.bin of=/dev/sda
```

然后安装extlinux

```sh
mount /dev/sda1 /mnt
cp /path/to/bzImage /mnt
cp extlinux.conf /mnt
output/host/sbin/extlinux --install /mnt
umount /mnt
```

将boot分区挂载之后，拷贝内核和extlinux配置文件。配置文件的内容如下:

```
TIMEOUT 50
DEFAULT linux

LABEL linux
SAY Now the kernel from SYSLINUX...
LINUX bzImage
APPEND root=/dev/sda2 ro console=tty1 quiet
```

该配置文件告诉extlinux读取当前目录下的bzImage作为内核映像并传递`APPEND`后指定的
参数给内核。

最后`extlinux --install`将会安装`ldlinux.sys`和`ldlinux.c32`到boot分区。gptmbr
加载并执行ldlinux.sys之后，ldlinux.sys会加载执行ldlinux.c32，这是syslinux的核心
模块。它会读取配置文件，并执行读取bzImage，解压、校验、执行等操作。

syslinux还有其他可选的模块，例如为了显示启动菜单，需要menu.c32或vesamenu.c32。

## 安装文件系统

在上面的extlinux.conf中，将`root=/dev/sda2`传递给了内核，意味这/dev/sda2将作为
根文件系统分区。于是需要将根文件系统部署在该分区上，命令很简单:

```sh
mount /dev/sda2 /mnt
cpio -D /mnt -idm < output/images/rootfs.cpio
umount /mnt
```

挂载sda2分区，然后将文件系统提取到分区上即可。

# Outro

以上是很简单的一个如何基于extlinux做系统的记录，大部分的USB系统启动盘也是通过类
似的方法制作的，有兴趣的可以试试。

[1]: https://wiki.syslinux.org/wiki/index.php?title=SYSLINUX
[2]: https://wiki.syslinux.org/wiki/index.php?title=EXTLINUX
[3]: https://wiki.archlinux.org/index.php/syslinux#Boot_process_overview
[4]: /post/buildroot_intro
