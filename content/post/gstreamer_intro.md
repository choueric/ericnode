---
title: GStreamer插件架构简析
author: zhs
type: post
date: 2016-01-20T07:55:53+00:00
mytory_md_mode:
  - text
views:
  - 1345
categories:
  - tech
tags:
  - c
  - gstreamer
blackfriday:
  extensions:
    - joinLines

---

# Intro
    
编写了两个GStreamer插件，对GStreamer的插件架构有了一些了解，这篇文章分析了插件
之间如何进行协商、数据如何流动。分析的代码主要是BaseSrc和VideoEncoder。文章对与
GStreamer基础的命令（gst-launch和gst-inspect）和概念不进行说明。
    
这里使用的GStreamer版本为**1.4.5**。

GStreamer官方文档好像只有manual（针对Application)和pwg（针对插件编写），文档内
容较为简单，更多是概括性的讲解，有提示的作用，但并不十分深入。而官网上的
Reference（例如[Core Reference]
(http://gstreamer.freedesktop.org/data/doc/gstreamer/head/gstreamer/html/index.html)）
基本是由GStreamer代码中的注释自动生成。因此，在读完manual和pwg之后，要写插件，
最终还是要__Read The Fucking Code__。
    
这里的两个插件分别为:

- testsrc：source类型插件，从专有设备中读取原始视频帧（video/x-raw格式），并
  push到downstream
- testenc：encoder类型插件，接受raw视频数据，通过硬件编码器码为H264格式，并push
  到downstream
    
因为要操作专有设备，所以现有插件是不满足要求的。最后运行时的pipeline为:

	testsrc -> testenc -> filesink

执行命令:

	$ gst-launch-1.0 testsrc ! testenc ! filesink location=save

文件`save`保存了H264编码格式的视频信息。

# 调试

这里先简单说明一下如何在插件开发过程中进行调试。在pwg文档中的`27.2`章节和manual
文档中的`23.2`章节中，说明了如何使用GStreamer自身提供的日志机制。

简单来说，在插件方面:

1. 打印语句不要使用`printf()`或`g_print()`，而是使用GStreamer提供的函数，例如
   `GST_DEBUG()`、`GST_LOG_OBJECT()`
2. 设置插件自身的debug策略，插件模板中已经有了，由宏`GST_DEBUG_CATEGORY_STATIC`定义
3. 使用`GST_DEBUG_FUNCPTR`宏来注册回调函数，以便后续debug时方便查看

调试时:

1. 使用`$ gst-launch --gst-debug-help`命令查看当前支持日志打印的模块和名称
2. 使用`--gst-debug`选项指定日志打印的模块和级别。例如，打开testsrc和testenc的
   所有级别日志，命令为:

	$ gst-launch-1.0 --gst-debug=testsrc:9,testenc:9 testsrc ! testenc ! filesink location=save

日志级别从0到9，0为关闭所有日志，9为开启所有日志。

更多和调试相关的信息，参考manual和pwg文档。

# 代码分析

pwg文档中说明了如何下载插件模板并使用脚本生成插件源码和编译工程，利用autotool工
具编译和安装，如何设置环境变量以及使用`gst-inspect`查看插件信息。

在完成了以上步骤之后，才开始真正编写插件。对于source类型和encoder类型的插件，
GStreamer的源码里有不少现成的插件代码可以参考，我主要参考了V4l2Src和
TheoraEncoder，在plugin-good和plugin-base包中可以找到。

和V4l2Src一样，source类型的插件可以直接继承BaseSrc或者PushSrc，里面已经实现了大
部分source相关的功能，包括negotiate、query、event、时间戳等；而TheoraEncoder这
类的encoder插件则继承自VideoEncoder。

继承的好处是，基类中已经实现了该类型插件的基本功能和框架，包括协商、处理事件、
处理查询，子类只需要针对自身的使用场景，编写对应的成员函数替换默认实现即可。坏
处则是，必须先阅读对应基类的代码，了解其运行机制，才能比较明确地把握基类成员函
数的作用、哪些需要覆盖、哪些可以使用默认。

因为我编写的TestSrc和TestEnc，分别继承自PushSrc和VideoEncoder，因此这里也只分析
BaseSrc、PushsSc和VideoEncoder的代码，描述插件之间如何进行协商、数据如何流动。
GStreamer官网上也有BaseSrc和VideoEncoder的说明文档，不过是由代码里的注释自动生
成。选择了使用继承的方式来编写插件，就必须阅读父类代码，充分了解父类的运行机制，
熟悉框架的各个接口，才能实现定制的功能和行为。

以下的分析需结合GStreamer的gstreamer、plugin-good和plugin-base三个源码包进行查
看。Linux下可以使用Eclipse或者Kscope之类的代码查看工具，方便在定义、引用之间来
回跳转。同时，在运行时开启debug日志，也有助了解代码的运行。

## 初始化 Initiate

两个插件的初始化是类似的。首先在头文件中对类和结构体指定继承的父类。

```c
struct _GstTestSrc
{
  GstPushSrc pushsrc;

  /* private */
  gboolean silent;
  gboolean is_phy_addr;
  unsigned int frame_count;
  int index;
};

struct _GstTestSrcClass
{
  GstPushSrcClass parent_class;
};

```

这样的话，通过`gst-inspect`可以查看到GstTestSrc的继承关系:

```
GObject
 +----GInitiallyUnowned
       +----GstObject
             +----GstElement
                   +----GstBaseSrc
                         +----GstPushSrc
                               +----GstTestSrc
```

TestSrc中，GstPushSrc和GstPushSrcClass必须放在结构体的第一位置，以便能够在子类、
父类之间转换，实现面向对象。其中GstTextSrc为类的实例对象，里面可以存放运行时所
需的变量；GstTestSrcClass则为类，主要定义成员函数。对于TestEnc，定义类似。

模板生成的代码里，函数
`static void gst_test_src_class_init (GstTestSrcClass * klass)`为类的初始化函数
，主要用来设置其成员函数（即回调函数），通过参数klass和各种宏，可以得到继承关系
上的所有父类，以便覆盖父类的成员函数。BaseSrc和VideoEncoder这样的类，一方面将自
己的函数设置到GstElement提供的框架中，实现更细分的功能；另一方面，自身定义了一
些接口函数（并提供默认实现）提供给子类。

模板中已经包含了GstObject所属的set_property和get_property函数、GstElement所属的
change_state函数。其中TestSrc中只有src pad，需要定义src pad template；TestEnc需
要定义src pad和sink pad的template。其他函数则在下面进行说明。

`gst_mw_src_init(GstTestSrc * src)`为对象的初始化函数，对GstTestSrc的成员变量进
行初始化。

BaseSrc的初始化如下图所示:

![src init](/gstreamer_intro/src_init.png)

BaseSrc的class_init中设置了GstElement的change_state回调和pad_active回调:

- gstelement_class->change_state = GST_DEBUG_FUNCPTR (gst_base_src_change_state);
- gst_pad_set_activatemode_function (pad, gst_base_src_activate_mode);

如上图所示，GstElement框架调用`gst_base_src_activate_mode()`，以push模式激活
src pad。在`gst_base_src_start()`中，调用了回调函数`start()`。如果TestSrc中有定
义该回调（这里为`test_src_start()`），则调用，一般用进行设备的初始化。其中函数
`gst_pad_mark_reconfigure()`将pad标识为需要进行协商，以便后续的过程中与
downstream的插件进行协商和配置。

接下来，GstElement调用`gst_base_src_change_state()`，将状态切换为playing。其中
`gst_base_src_set_playing()`里调用`gst_pad_start_task()`，将`gst_base_src_loop()`
函数设置为source组件的任务处理例程，循环调用，由此在push模式下，从整个组件链条
的最上端，开始将数据往下推送。

对于TestEnc来说，初始化流程类似，不再赘述。

## 协商 Negotiate

### TestSrc与TestEnc协商

在`gst_base_src_loop()`中，有如下代码:

```c
/* check if we need to renegotiate */
if (gst_pad_check_reconfigure (pad)) {
  if (!gst_base_src_negotiate (src)) {
    gst_pad_mark_reconfigure (pad);
    if (GST_PAD_IS_FLUSHING (pad)) {
      GST_LIVE_LOCK (src);
      goto flushing;
    } else {
      goto negotiate_failed;
    }
  }
}
```

每次都会检查是否需要重新进行协商，以便应对配置的动态变化。如上所述，在初始化时
标识了需要进行reconfigure，因此TestSrc开始进行协商。该过程会询问很多东西，但最
重要的是caps和allocation。

流程如下图所示:

![src negotiate with encoder](/gstreamer_intro/mwsrc_negotiate_with_encoder.png)

在`gst_base_src_negotiate()`中，有机会调用子类的negotiate函数，如果子类没有设置，
则用BaseSrc的默认协商函数`gst_base_src_default_negotiate()`，这里使用默认函数。

在该函数中，使用gst_pad相关函数执行query_caps。发出query后，在VideoEncoder类中，
由其sink pad的query处理函数`gst_video_encoder_sink_query()`来响应。在里面调用
`encoder_class->sink_query`，这里使用默认函数`gst_video_encoder_sink_query_default()`，
由该函数处理所有的query。针对caps，调用`gst_video_encoder_sink_getcaps()`，如果
子类实现了`klass->getcaps()`，则由子类决定sink pad具有什么样的caps；否则调用
`gst_video_encoder_proxy_getcaps（）`，从template上获得caps。

在VideoEncoder回应了caps query之后，BaseSrc获得TestEnc sink pad的caps，然后调用
fixate函数，根据得到的caps来确定实际src pad输出的格式。其中`bclass->fixate`需由
子类实现，以便确定输出格式，包括宽、长等。

完成caps的协商之后，使用`gst_pad_get_current_caps()`获取当前的caps，然后调用
`gst_base_src_prepare_allocation()`来设置内存的分配。该函数首先对VideoEncoder进
行allocation查询。VideoEncoder调用`klass->propose_allocation`来应答。如果子类有
对内存的特别需求，则必须实现该回调函数，否则执行默认处理函数将会返回NULL，意味
着后续将会使用系统默认的allocator（即_“SystemMemory”_）。这里encoder采用硬件编
码，必须存放到硬件的物理地址，因此实现了自定义的allocator来提供该物理地址。

**Memory Allocation**在GStreamer中比较重要，大家可以参考pwq文档，有专门的一章节
`Chapter 15. Memory Allocation`进行讲解。不过其中
`15.1.3. Implementing a GstAllocator`是空缺的... 关于GstBuffer、GstMemory和
GstBufferPool的关系以及使用，估计得要另一篇文章才能说清楚。

TestEnc将allocator和pool设置在query中并返回给BaseSrc，BaseSrc调用
`bclass->decide_allocation`来决定是否采纳该allocator，默认函数只做了一些有效性
检查。然后解析出pool和allocator，并将其保存下来，留在以后使用。到这里，TestSrc
对TestEnc的协商完成。

### TestEnc与FileSink协商

TestSrc开始采集视频数据后，会调用`gst_pad_push()`将数据由自身的src pad推到
TestEnc的sink pad，GStreamer框架将会调用插件的chain函数进行处理，即VideoEncoder
定义的`gst_video_encoder_chain()`。

在该函数中，有如下代码:

```c
if (G_UNLIKELY (encoder->priv->do_caps)) {
  GstCaps *caps = gst_pad_get_current_caps (encoder->sinkpad);
  if (!caps)
    goto not_negotiated;
  if (!gst_video_encoder_setcaps (encoder, caps)) {
    gst_caps_unref (caps);
    goto not_negotiated;
  }
  gst_caps_unref (caps);
  encoder->priv->do_caps = FALSE;
}
```

在其中，调用`gst_video_encoder_setcaps()`对sink pad进行配置，如下图中上方的虚线
框内所示:

![encoder negotiate with downstream](/gstreamer_intro/encoder_negotiate_with_downstream.png)

在第一个虚线框中，主要目的是为了建立input_state，用来保存输入数据的配置，子类必
须实现`encoder_class->set_format`，将协商好的格式初始化到赢家中。

在VideoEncoder设置好input部分后，chain函数继续执行，将会调用`klass->handle_frame`，
用来处理由TestSrc传入的视频帧数据，子类必须实现。参考TheoraEncoder的实现，发现
在它的handle_frame中，首先会使用单键进行初始化，对src pad和output进行配置，如图
中第二个虚线框内所示。

首先获取自己src pad的caps，并调用`gst_video_encoder_set_output_state()`将其传入
来设置output格式。然后调用`gst_video_encoder_set_output_state()`，和downstream
的插件（即FileSink）进行协商。协商过程中有两个回调函数提供给子类来实现，
negotiate函数和decide_allocation函数，这里均使用默认实现。该协商过程和之前
TestSrc与TestEnc的协商过程大致相同。

至此，三个插件的协商完成，确定了插件与插件之间的传输数据格式（`video/x-raw`和
`video/x-h264`），设置了生成相互之间传输数据GstMemory所使用的allocator和pool。

## 数据流

协商完成之后，就开始实际数据传输。在这里的应用场景里，数据（即视频帧）的流向如
下所示:

	(device) testsrc --(video/x-raw)--> testenc --(video/x-h264)--> filesink (file)

TestSrc从device中采集到raw格式数据，传输给TestEnc；TestEnc使用硬件编码将raw格式
数据转换为H264格式，传输给FileSink；FileSink将其保存为文件。

大致的数据流描述如上，非常简单明了。但是对于插件开发者来说，代码执行就没那么简
单了。

### TestSrc Push to TestEnc

TestSrc将视频帧传输给TestEnc的执行流程如下图所示:

![src push frame to encoder](/gstreamer_intro/src_push_frame_to_encoder.png)

在此前初始化阶段提到，`gst_pad_start_task()`创建任务，使得`gst_base_src_loop()`
被循环调用。在loop函数中，执行协商之后，将调用`gst_base_src_get_range()`。

该函数首先获取长度，然后调用`bclass->create`，这里使用默认实现
`gst_base_src_default_create()`。该函数调用了`bclass->alloc`和`bclass->fill`，
其中alloc获取GstBuffer用来存放数据，fill负责往GstBuffer填充数据。之后，由
BaseSrc调用`gst_pad_push()`将帧发送给TestEnc。

在alloc中，调用`gst_base_src_get_buffer_pool()`获取pool，然后使用
`gst_buffer_pool_acquire_buffer()`从pool中获取GstBuffer。**需要注意**，如果pool
中已经没有可用的GstBuffer，即达到了pool的Max，那么该调用将会被阻塞，因此需要在
TestEnc中将处理后的GstBuffer重新放回到pool中。

在fill中，从专有设备中获取数据，并填充到GstBuffer。如pwg所说，需要使用
`gst_memory_map()`来获取可用的内存地址。而在自己实现的allocator中，此时才真正去
分配物理内存并返回给TestSrc使用。

将数据填充到GstBuffer之后，调用`gst_pad_push()`，将该GstBuffer传递给downstream。
随后TestEnc的sink pad的chain函数（即`gst_video_encoder_chain()`）被调用。这个函
数由父类VideoEncoder实现，完成了大部分功能，包括设置input_state、计算时间、分配
新的frame，而子类必须实现`klass->handle_frame`，处理获得的数据。

至此，视频帧便从Source传递到了Encoder。

### TestEnc Push to FileSink

视频帧在Encoder中以`GstVideoCodecFrame`结构体类型存在，该结构体同时表示了原始格
式和编码后格式的视频帧，文中以frame表示。

在TestEnc定义的`test_enc_handle_frame()`中，编码原始数据，然后传递给downstream。
参考了TheoraEncoder的实现，如下图所示:

![encoder push frame downstream](/gstreamer_intro/encoder_push_frame_downstream.png)

首先从GstBuffer取出raw格式数据，进行编码处理。编码之后，调用
`gst_video_encoder_get_oldest_frame()`获得一个新的frame，然后给该frame分配
output_buffer，即传递给FileSink的GstBuffer。这里使用的allocator为TestEnc和
FileSink协商得到的allocator，因此如果之前没有进行协商，这里会进行一次。

得到GstBuffer之后，调用`gst_buffer_fill()`将编码后的数据填充到里面，里面的实现
是使用的`memcpy()`。此时，要传输的frame就准备好了，最后调用
`gst_video_encoder_finish_frame()`。

finish_frame函数里在将GstBuffer传递给FileSink之前，会调用
`encoder_class->pre_push()`，TestEnc仍有机会对frame进行一些处理，例如时间同步之
类。从frame的output_buffer中得到GstBuffer后，release该frame，然后调用
`gst_pad_push()`将GstBuffer传给downstream。

最后FileSink接收到GstBuffer，并从中获得H264格式的视频帧，保存到文件中。这样便完
成了一次数据传输。

# 总结

以上只是非常粗略地描述了一下插件的基本工作流程，很多细节都没有提到，例如同步、
内存管理、信号处理、时间处理、参数配置等。不过在认识了运行机制的前提下，看代码
了解这些细节也不难了。
