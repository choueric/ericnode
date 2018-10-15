+++
draft = false
date = "2018-06-26T10:29:59+08:00"
title = "如何给ffmpeg添加codec"
description = "简单介绍如何在ffmpeg中添加新的codec以及简单实现"
isCJKLanguage = true
categories = ["tech"]
tags = ["c", "ffmpeg", "program", "video"]

[blackfriday]
  extensions = ["joinLines"]
+++

# Intro
--------------------------------------------------------------------------------

ffmpeg是一个很强大的框架，包含众多的编解码器、提供很多方便的函数用于解析或生成
各种媒体文件。大部分情况下，开发者使用ffmpeg开发应用程序，然而有时也有开发ffmpeg
本身的需求，例如添加私有的编解码器，让应用程序开发者能够方便的使用上该codec。

这里介绍如何在ffmpeg中添加一个codec，以H264 Encoder为例。这里使用的ffmpeg版本
为`0e56321`，commit的时间为`2017.09.26`。之所以这里明确说明版本号，是因为ffmpeg
经历过一次较大的API变化。网络上的例子和代码说明的文章，大部分都是针对以前旧的API，
例如雷神的文章。新的API主要是以`avcodec_send_frame`和`avcodec_receive_packet`代替
了之前的`avcodec_encode_video2`和`avcodec_decode_video2`。源码
`libavcodec/avcodec.h`中的注释给出了一些说明，如下：

```
This API replaces the following legacy functions:
- avcodec_decode_video2() and avcodec_decode_audio4():
  Use avcodec_send_packet() to feed input to the decoder, then use
  avcodec_receive_frame() to receive decoded frames after each packet.
  Unlike with the old video decoding API, multiple frames might result from
  a packet. For audio, splitting the input packet into frames by partially
  decoding packets becomes transparent to the API user. You never need to
  feed an AVPacket to the API twice (unless it is rejected with 
  AVERROR(EAGAIN) - then no data was read from the packet).
  Additionally, sending a flush/draining packet is required only once.
- avcodec_encode_video2()/avcodec_encode_audio2():
  Use avcodec_send_frame() to feed input to the encoder, then use
  avcodec_receive_packet() to receive encoded packets.
  Providing user-allocated buffers for avcodec_receive_packet() is not
  possible.
- The new API does not handle subtitles yet.
```

# 编译
--------------------------------------------------------------------------------

在添加新的codec之前，可以先编译一下ffmpeg。当然也可以直接添加，然后再编译，因为
添加codec会修改核心文件，会导致几乎所有文件都重新编译，而编译一次ffmpeg需要较多
时间。

这里创建一个编译脚本`build.sh`，内容如下:

```sh
#!/bin/bash

PREFIX=$HOME/ffmpeg_build
INC_PATH="-I$PREFIX/include"
LINK_PATH="-L$PREFIX/lib"

EXTERNAL_LIBS+="-lEGL -lGLESv2"
DEBUG_OPTS="--disable-stripping"

do_config() {
	PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" \
		./configure \
		--prefix="$PREFIX" \
		--pkg-config-flags="--static" \
		--extra-cflags="-g $INC_PATH" \
		--extra-ldflags="$LINK_PATH " \
		--extra-ldlibflags="$LINK_PATH" \
		--extra-libs="$EXTERNAL_LIBS" \
		--enable-shared \
		--disable-static \
		$DEBUG_OPTS \
		--enable-gpl \
		--enable-libx264 \
		--enable-nonfree
}

print_usage() {
	echo "Usage: config, make, install"
}

case "$1" in
	"config") do_config;;
	"make") make -j 4;;
	"example") make examples;;
	"install") make install;;
	*)
		print_usage
esac
```

## 编译 配置

首先进行配置，执行如下命令

```sh
$ ./build.sh config
```

如果出现如下错误

> nasm/yasm not found or too old. Use --disable-x86asm for a crippled build.

则需要安装汇编器nasm

```sh
$ sudo apt install nasm
```

因为是使能了libx264，如果出现如下错误

> ERROR: libx264 not found

需要安装libx264的开发文件

```sh
$ sudo apt install libx264-dev
```

## 编译安装

配置完成之后，执行编译和安装命令

```sh
$ ./build.sh make
$ ./build.sh install
```

最终，ffmpeg的头文件、库文件和其他文件将安装在`build.sh`中定义的`PREFIX`(这里为
`$HOME/ffmpeg_build`)目录下。

如果需要编译`doc/examples`目录下的测试程序。可以执行下面的命令:

```sh
$ ./build.sh example
```

# 添加codec
--------------------------------------------------------------------------------

关于一个codec文件内容如何、怎样组织，可以参考析代码`libavcodec/nvenc.c`。该
codec使用nvenc库，利用Nvidia GPU完成H264编码。

另外，也可以参考[FFmpeg codec HOWTO][2]。这篇文章同样介绍了如何在ffmpeg中添加一
个新的codec。

作为例子，这里假设添加一个名为new的、将NV12编码为H264 encoder。

## 添加codec源码

创建`libavcodec/new_enc_h264.h`，定义codec的私有数据结构。内容为:

```c
#ifndef AVCODEC_NEW_ENC_H264_H
#define AVCODEC_NEW_ENC_H264_H
 
#include "config.h"
#include "avcodec.h"
 
typedef struct _NewEncCtx {

}NewEncCtx;
 
#endif
```

创建`libavcodec/new_enc_h264.c`，包含该codec的回调函数和codec结构体。内容为:

```c
#include "new_enc_h264.h"
 
const enum AVPixelFormat ff_new_enc_pix_fmts[] = {
    AV_PIX_FMT_NV12,
    AV_PIX_FMT_NONE
};

static av_cold int ff_new_enc_init(AVCodecContext *avctx)
{
    av_log(avctx, AV_LOG_VERBOSE, "%s\n", __func__);
 
    return 0;
}
 
static av_cold int ff_new_enc_close(AVCodecContext *avctx)
{
    av_log(avctx, AV_LOG_VERBOSE, "NewEnc unloaded\n");
 
    return 0;
}
 
static int ff_new_enc_receive_packet(AVCodecContext *avctx, AVPacket *pkt)
{
    av_log(avctx, AV_LOG_WARNING, "Not implement.\n");
    return AVERROR(EAGAIN);
}
 
static int ff_new_enc_send_frame(AVCodecContext *avctx, const AVFrame *frame)
{
    av_log(avctx, AV_LOG_WARNING, "Not implement.\n");
    return AVERROR(EAGAIN);
}

AVCodec ff_h264_new_encoder = {
    .name           = "new_enc",
    .long_name      = NULL_IF_CONFIG_SMALL("New H264 Encoder"),
    .type           = AVMEDIA_TYPE_VIDEO,
    .id             = AV_CODEC_ID_H264,
    .priv_data_size = sizeof(NewEncCtx),
    .init           = ff_new_enc_init,
    .close          = ff_new_enc_close,
    .receive_packet = ff_new_enc_receive_packet,
    .send_frame     = ff_new_enc_send_frame,
    .pix_fmts       = ff_new_enc_pix_fmts,
};
```

## 添加到libavcodec

为了将`new_enc`加到libavcodec中，让外部程序调用，需要添加注册语句。

首先，在`libavcodec/allcodecs.c`中的函数`avcodec_register_all`里注册new_enc，
添加语句`REGISTER_ENCODER(H264_NEW,          h264_new);`。

如果是注册decoder，使用`REGISTER_DECODER`；如果是同时注册encoder和decoder，使用
`REGISTER_ENCDEC`。


然后，在`libavcodec/Makefile`中加入新的codec: 

`OBJS-$(CONFIG_H264_NEW_ENCODER)        += new_enc_h264.o`

## 重新编译

修改源码之后，需要重新进行配置`./build.sh config`。之后可以在
`ffbuild/config.mak`中确认`CONFIG_H264_NEW_ENCODER`是否使能。

然后执行编译和安装。为了使用编译出来的库，需要设置库的搜索路径`LD_LIBRARY_PATH`:

```sh
$ ./build.sh make
$ ./build.sh install
$ export LD_LIBRARY_PATH=$HOME/ff_build/lib
```

运行

```sh
$ ./ffmpeg -encoders | grep new
```

将打印当前的支持的encoders，可以看到有new_enc。

# 实现
--------------------------------------------------------------------------------

以上其实已经介绍完成了如何添加新的codec。只不过代码只是空架子，并没有实现实际的
功能。要让codec工作起来，需要将各个回调函数实现，这涉及到如何使用ffmpeg内部API。

ffmpeg的内部API，和外部API一样，并没有很好的文档说明，更多的还是需要开发者自己
看实现源码、读注释以及参考其他实现。这里假设new_enc内部使用类似openMAX IL的接口
来实现实际编码功能，包括:

- GetEmptyBuffer: 获取空闲内存，用于存放原始数据
- EmptyThisBuffer: 将原始数据提交给编码器
- GetFilledBuffer: 获取编码之后的内存
- FillThisBuffer: 返回编码内存

## priv_data

结构体`NewEncCtx`，作为new_enc的私有结构，里面存放着和具体实现相关的数据，作为
`AVCodecContext`的priv_data存放，在各个回调函数中获取得到。

```c
#define to_NewEncCtx(avctx) ((NewEncCtx *)(avctx)->priv_data)
NewEncCtx *ctx = to_NewEncCtx(avctx);
```

## init & close

```c
int ff_new_enc_init(AVCodecContext *avctx)
```

该回调函数实现初始化工作，可能包括对编码器的硬件初始化、内存分配、私有数据的初
始化等等。

```c
int ff_new_enc_close(AVCodecContext *avctx)
```

释放init中的分配的资源。

## send_frame

```c
int ff_new_enc_send_frame(AVCodecContext *avctx, const AVFrame *frame)
```

该函数通过`AVFrame`，传递一帧视频原始数据(这里为NV12格式)给codec，在该函数内部
实现对该帧的处理。通常的处理过程为:

1. 使用GetEmptyBuffer获取空闲内存
2. 将@frame中的数据放入到空闲内存中。因为frame数据量较大，且视频格式多样，这一
   步可能涉及到调用特定接口实现加速拷贝。
4. 使用EmptyThisBuffer将填充后的内存放入到编码器中进行编码。

## receive packet

```c
int ff_new_enc_receive_packet(AVCodecContext *avctx, AVPacket *pkt)
```

该回调函数负责将编码后的数据放入到`AVPacket`中。ffmpeg使用`AVPacket`存放编码后
的数据，与`AVFrame`相对应。通常的处理过程如下:

1. 调用GetFilledBuffer接口函数，获取编码内存
2. 调用ff_alloc_packet2，给@pkt分配足够的空间存放编码后的数据。
3. 从编码内存中拷贝数据到@pkt。这一步数据量通常较小，不需要特殊处理。
4. 调用FillThisBuffer将处理后的编码内存返回给编码器。

## 测试

完成以上回调函数之后，就能实现基本的编码功能了。重新编译之后，可以使用`ffmpeg`
程序快速的进行验证。

以下的命令将NV12格式的文件`raw_nv12_1920x1080`，使用`new_enc`编码器进行编码，
输出到`output.mp4`文件中。

```c
$ ./ffmpeg -f rawvideo -pixel_format nv12 -framerate 30 -video_size 1920x1080 -i raw_nv12_1920x1080 -c:v new_enc output.mp4
```

如果想要以代码的形式，编写应用程序调用ffmpeg库进行测试，可以参考[这个例子][1]。

# 总结
--------------------------------------------------------------------------------

要在ffmpeg中真正地实现一个codec，除了以上一些基本的工作之外，仍然需要对ffmpeg
和视频格式更多的理解才行。虽然ffmpeg的文档缺少和不怎么更新一直被人诟病，但是代
码结构还是比较清晰的，因此比起GStreamer来，我还是愿意开发ffmpeg。

[1]: https://github.com/choueric/ffmpeg_demos/tree/master/encode_video
[2]: https://wiki.multimedia.cx/index.php/FFmpeg_codec_HOWTO
