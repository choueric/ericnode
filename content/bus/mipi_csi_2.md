+++
isCJKLanguage = true
date = "2017-05-02T11:23:52+08:00"
title = "MIPI CSI-2简介"
categories = ["Tech", "bus"]
tags = ["bus", "embedded"]
draft = true
description = "simple introduction of MIPI CSI2"

[blackfriday]
  extensions = ["joinLines"]

+++

# 概述

本文简单介绍MIPI CSI-2协议，根据MIPI联盟的官方文档
`MIPI Alliance Specification for Camera Serial Interface 2 (CSI-2)`，描述其协议
层次和应用场景。

CSI (Camera Serial Interface) 是MIPI定义的规范，用于连接摄像头和CPU，传输摄像头
的视频信号，最新的规范是2012发布的CSI-3，使用的物理层为M-PHY。而这里要介绍的
CSI-2规范在2005发布、使用D-PHY作为物理层。DSI(Display Serial Interface)同样基于
D-PHY，不同的是，它主要用于host将图像传输给显示设备。

在手机的应用中，一般的SoC至少会有两个CSI Receiver控制器，分别用于连接前置和后置
摄像头。

下图为CSI-2的物理连接:

![Fig1.CSI-2 CCI connection](/mipi_csi2/CSI-2_CCI_connection.png)

从图中可以看到，CSI-2接口包含两种连接: CSI和CCI。

CCI (Camera Control Interface) 为双向连接，兼容I2C协议。该接口主要用来访问camera
中的寄存器，以便对其进行配置和控制。通常使用host的I2C host控制器，而camera则作
为I2C slave device。不同的厂家的camera寄存器布局和字段定义是不同的。

CSI接口为单向传输，包括一个clock lane和一到四个的data lane组成，传输图像数据。
采用D-PHY物理层协议。

像USB、Ethernet一样，复杂的协议一般都会分层，方便将复杂的功能拆解，逐个实现和验
证。下图为CSI-2的协议栈:

![Fig2.CSI-2 Layers](/mipi_csi2/csi-2_layers.png)

从上到下，分别是:

- 应用层
- CSI协议:
  - pixel/byte转换层
  - Low Level Protocol层
  - Lane Management层
- 物理层

下面分别进行介绍。

# D-PHY物理层

物理层定义了CSI传输介质的电气特性、帧格式以及时钟等。如下图所示:

![Fig3.D-PHY](/mipi_csi2/d-phy.png)

CSI中有clock lane和data lane，每个lane包括两个引脚，传输串行差分信号。clock lane
传输时钟信号，接收端根据时钟对data lane的引脚进行采样获取数据。

D-PHY有两种工作状态：低功耗(LP)和高性能(HS)。LP模式下处于单端模式，传输的信号是
单端信号，通常用来维持连接；HS模式下则传输的是差分数据信号。

在data lane上进行数据传输时，一开始发送SoT(start of transmission)信号，然后发送
数据payload，最后以EoT(end of transmission)结束，这样为一个完整的物理层上的数据
包。接收端通过SoT和EoT识别数据包并获取payload，然后交给上层解析。

对物理层的访问和控制，是通过PPI(PHY Protocol Interface)进行的。

# CSI协议层

在物理层之上，即是CSI协议层，由三层构成，每一层有着明确的功能。

## Pixel/Byte Packing/Unpacking Layer

这一层中，发送端接收来自应用层的像素数据，并打包成字节格式发送到下一层；在接收
端，解包来自LLP层的数据并传输到应用层。

该层的主要目的是将不同像素格式(例如YUYV, RGBA等)都转换成为8bit字节格式，消除不
同图像格式差异，减少传输的复杂度。例如，对于RGB888格式，一个pixel为24 bit，将转
换为三个字节；RGB565格式，一个pixel为16 bit，转换为两个字节。而对于RGB444，大小
为12 bit，需要通过padding变成RGB565格式，为两个字节，如下图所示:

![Fig4.RGB444-conversion](/mipi_csi2/rgb444-pad.png)

## Low Level Protocol

Low Level Protocol(LLP)层为CSI协议的主要功能层，不仅定义了包格式，还定义了传输
中使用的同步机制。

在发送端，该层负责将上层传输过来的数据打包，添加校验字段，增加同步包，发送到下
一层；在接收端首先校验包的完整性，并解析各个字段，根据包类型执行对应操作，将图
像数据传到上一层。

LLP处理的playload数据为经过转换后的纯字节数据，没有像素概念。通过定义不同的的字
段和包类型，实现一帧一帧图像数据的传输。

## Lane Management

CSI-2是可以根据性能要求使用data lane进行扩展的。针对不同的带宽要求，data lane的
数目可以是一、二、三或者四。发送端根据使用的lane数目，自动将数据分发到各个lane
上进行传输；在接收端则将各个lane上的数据重新合并，恢复数据。

该层将LLP传输过来的packet当作一段纯字节数据，根据lane数目进行分发，而不考虑包里
的数据意义。

例如，对于4个lane的发送，按如下方式分发:

![Fig5.four lane distribution](/mipi_csi2/four_lane_distribute.png)

通过这样的转换之后，一个packet在lane上的传输情况如下图所示:

![Fig6.four_lane_transfer](/mipi_csi2/four_lane_transfer.png)


从上面的说明可知，pixel/byte转换层的作用为消除pixel格式差异、简化传输，
lane management层的作用为分发和拼接packet、提高带宽。这两层都是对数据进行单纯的
转换，而不涉及功能逻辑。LLP层才是和传输机制密切相关。因此在后面的讨论中，展示出
来的包格式，将只涉及到LLP层，忽略掉其他两层对包格式的作用，即不考虑pixel与byte
的转换而直接显示pixel，不考虑lane的拆分而直接在一个lane上展示，如下图所示:

![Fig7.llp](/mipi_csi2/llp_layer.png)

上图展示了数据传输，黄色背景色的ST(SoT)、ET(EoT)是物理层所添加的包，和中间的数
据包一起，表示一次传输。LPS即Low Power State，Dp-Dn处于低功耗工作状态，此时不传
输数据。而SP(Short Packet)和LP(Long Packet)为LLP层所定义的包，用于同步以及帧图
像数据传输。

# 传输一帧图像

LLP作为主要功能的实现，定义了很多包类型、字段和传输机制。这里不详尽地罗列这些细
节，而是讲述一下一帧图像在总线上的传输格式，给出一个直观、感性的理解。关于LLP的
详细细节，可以参考协议的`Chapter 9 Low Level Protocol`。

LLP的packet主要有两种: SP (short packet)和LP (long packet)。一个LP包含一行图像
数据，一个SP则用来进行特殊的用途，主要是同步，例如表示帧开始(FS)、帧结束(FE)、
线开始(LS)和线结束(LE)。其中LS和LE是可选的。

同时协议规定，每个packet之间，必须有一个LPS状态，即packet spacing。因此在进行传
输时，总线上传输的是SoT+SP+EoT、SoT+LP+EoT和LPS。

一帧必须以FS包开始，以FE包结束，中间为帧高度个数的LP包，每个包含一行图像数据。
如下图所示:

![Fig8.one frame on bus](/mipi_csi2/one_frame.png)

图中底部的VVALID、HVALID和DVALID表明垂直有效和水平有效。

传输一开始，首先传输FS类型的SP包，表示一帧图像数据开始，进行帧同步。

然后传输图像数据，一行数据一个LP包。每个LP包由PH (packet header)、Data和
PF (packet footer)组成，各字段定义如下如下图所示:

![Fig9.long packet structure](/mipi_csi2/lp.png)

其中Data字段中的内容，根据不同的图像格式，其组织方式也不一样。这即为上一章
Pixel/Byte转换层的内容。关于Data的格式，可以参考`Chapter 11 Data Formats`。

如RGB565的格式如下:

![Fig10.RGB565 data format](/mipi_csi2/rgb565_data_format.png)

在一帧图像的所有数据包传输之后，最后传输一个FE类型的LP包，表示一帧的结束。

# Linux驱动

在Linux系统中，要使用CSI进行图像传输，还需要两种驱动:CSI receiver驱动和
CSI sender驱动。

CSI receiver驱动用来控制SoC上的CSI外设，读取CSI总线上的数据并输出到内存或者ISP
上，位于drivers/media/platform/soc_camera。一方面，驱动实现soc_camera子系统和
v4l2子系统需要的结构体和回调函数，成为一个v4l2 device，以/dev/video接口暴露给用
户层；另一方面，控制SoC中的CSI硬件并调用它的subdev接口，实现具体的传输。

CSI sender驱动，即camera sensor驱动，位于drivers/media/i2c中。一方面，该驱动通
过I2C与sensor通信，配置参数、启动或停止传输图像；另一方面实现soc_camera子系统所
需的结构体和回调函数，作为v4l2 device的subdev，提供接口给receiver驱动调用。

通过soc_camera和v4l2子系统框架，sensor驱动和host驱动相互独立，能够被复用。

# 总结

本文介绍了CSI-2协议的层次结构，展现总线上实际数据传输情况，提供一个感性的认识。
驱动方面的介绍非常简单，没有涉及细节，因为实现细节和内核版本有关，v4l2子系统和
soc_camera子系统也一直在进化。

和I2C、SPI总线不同的是，CSI总线因为速度高，需要性能较高的示波器才能进行在线分析。
重要的是了解其中的概念，在写驱动时有帮助。

参考:

- [MIPI（CSI-2）之从bit流中获取图像数据][1]
- [V4L2 soc camera 分析 - 系统架构图][2] 
- 文中图片均来自`MIPI Alliance Specification for Camera Serial Interface 2 (CSI-2)`。

[1]: http://blog.csdn.net/duinodu/article/details/48479325
[2]: http://blog.csdn.net/kickxxx/article/details/8484498
