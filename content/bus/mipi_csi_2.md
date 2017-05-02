+++
isCJKLanguage = true
date = "2017-05-02T11:23:52+08:00"
title = "MIPI CSI-2 接口简介"
categories = ["Tech", "bus"]
tags = ["bus", "embedded"]
draft = true
description = "simple introduction to MIPI CSI2 interface"

[blackfriday]
  extensions = ["joinLines"]

+++

# Intro

本文简单介绍MIPI CSI-2接口，内容基本来自MIPI联盟的官方文档
`MIPI Alliance Specification for Camera Serial Interface 2 (CSI-2)`和
`MIPI Alliance Specification for D-PHY`。

CSI(Camera Serial Interface)是MIPI定义的规范，主要用于连接摄像头和主CPU，传输
摄像头的视频信号，最新的规范是2012发布的CSI-3，使用的物理层为M-PHY。而这里要介绍
的CSI-2在2005发布、使用的物理层为D-PHY。随着手机的应用，一般的SoC至少会有两个
CSI Receiver控制器，分别用于连接前置和后置摄像头。摄像头作为sender，提供时钟信号
和数据信号，host端的receiver接收并解析数据信号，将图像送到内存或ISP中进行处理。

DSI(Display Serial Interface)同样也是基于D-PHY，不同的是，host作为sender提供时钟
信号和数据信号，将图像传输给显示设备(即receiver)进行显示。

下图为CSI-2的连接方式:

![Fig1.CSI-2 CCI connection](/mipi_csi2/CSI-2_CCI_connection.png)

CSI-2接口包含了两种类型连接: CSI和CCI。

其中CCI(Camera Control Interface)为双向连接，兼容I2C协议。在实际使用中，使用host
端I2C host控制器对camera的寄存器进行访问，不同的camera有不同的寄存器使用方法。

CSI接口是单向传输有一个clock lane和一到四个的data lane组成，传输实际的图像数据
给host。该部分接口采用D-PHY物理层协议。

像USB、Ethernet一样，复杂的协议一般都会分层，方便将复杂的功能拆解，逐个实现和验
证。下图为CSI-2的协议层:

![Fig2.CSI-2 Layers](/mipi_csi2/csi-2_layers.png)


# D-PHY物理层

物理层定义了传输介质的电气特性、时钟以及如何从串行比特流中获取到数据等。如下图
所示:

![Fig3.D-PHY](/mipi_csi2/d-phy.png)

CSI中有clock lane和data lane，每个lane有两个引脚，以传输串行差分信号。clock lane
用于传输时钟信号，接收端根据时钟对data lane的引脚进行采样获取实际数据。

D-PHY有两种工作状态：低功耗(LP)和高性能(HS)。LP模式下处于单端模式，传输的信号是
单端信号，通常用来维持连接；HS模式下则传输的是差分信号。

在data lane上进行数据传输时，一开始发送SoT(start of transmission)，然后发送数据，
最后以EoT(end of transmission)结束，这样为一个完整的物理层上的数据包。接收端通过
SoT和EoT识别数据包并获取payload。

# CSI协议层

在物理层之上，即是CSI自身协议层。如图所示，这部分分成了三层，每一层有着明确的分
工。

对物理层的访问和控制，是通过PPI(PHY Protocol Interface)进行的。

## Pixel/Byte Packing/Unpacking Layer

CSI-2支持多种pixel格式，最小6bits，最大24bits。在这一层中，发送端接收来自应用层
的像素数据，并打包成字节格式发送到下一层(LLP)；在接收端，解包来自LLP层的数据并
传输到应用层。

该层的主要目的是将不同像素格式(例如YUYV, RGBA等)都转换成为8bit字节进行传输，消
除不同图像格式差异，减少传输中的复杂度。例如，对于RGB888格式，一个pixel为24bit
大小，转换为三个字节。对于RGB565，一个pixel为16bit，转换为两个字节。而对于RGB444，
通过padding变成RGB565格式，转化成为两个字节，如下图所示:

![Fig4.RGB444-conversion](/mipi_csi2/rgb444-pad.png)


## Low Level Protocol

Low Level Protocol(LLP)层为主要的功能层，定义了协议中使用的两种包格式，long packet和
short packet。

在发送端，该层负责将上层传输过来的数据打包，定义不同的包字段，添加校验字段，并
发送到下一层；在接收端首先校验包的完整性，并解析各个字段，执行相关操作，传送数
据到上一层。

LLP处理的playload数据为经过转换后的纯字节数据，没有像素概念。通过定义不同的不同
的字段、不同的包类型，实现实际的协议功能。保证传输正确性。传输给下层的为packet。

## Lane Management

CSI-2是可以根据性能要求使用data lane进行扩展的。针对不同的带宽要求，data lane的
数目可以是一、二、三或者四。发送端根据使用的lane数目，自动将数据分布到各个lane
上进行传输；在接收端则将各个lane上的数据重新合并，恢复为发送的数据。

该层将LLP传输过来的数据当初纯字节数据，即一个packet。主要作用是将一个packet通过
配置分发到多个lane中进行传输。

例如，对于4个lane的发送，按如下方式分发:

![Fig5.four lane distribution](/mipi_csi2/four_lane_distribute.png)

通过这样的转换之后，一个packet在lane上的传输情况如下图所示:

![Fig6.four_lane_transfer](/mipi_csi2/four_lane_transfer.png)


从上面的讨论可知，pixel/byte转换层是为了简化传输，lane management层是做了一个分
发packet和拼接的作用。这两层是对数据进行拼接和拆解操作，并没有对功能逻辑上有影响，
因此后续在进行功能讨论时将忽略，集中讨论在LLP层，传输的示意图也将忽略掉这两次的
影响，不考虑pixel与byte的转换而直接显示pixel，不考虑lane的拆分而直接在一个lane
上展示，如下图所示:

![Fig7.llp](/mipi_csi2/llp_layer.png)

图中为一次数据传输，黄色背景色的ST(SoT)、ET(EoT)为物理层所添加的包。LPS即Low Power State，Dp-Dn处于低功耗工作状态，此时是不传输数据的。
而SP(Short Packet)和LP(Long Packet)即为实际作用的包了，完成一帧图像数据传输。

# 应用层

该层描述了如何解析数据流中的像素，CSI-2规范描述了像素和字节的映射关系。Chaper 12。

# 如何传输一帧图像

除了LLP之外，CSI协议中的其他协议层都比较好理解和简单。而LLP作为主要功能的实现，
包含了较多的包类型定义、字段定义和传输机制。这里不简单和详尽地罗列这些细节，而是
讲述一下一帧图像如何在总线上进行传输，给出一个直观的印象。关于LLP的详细细节，可以
参考协议的Chapter 9。

协议规定，每个LLP的packet之间，必须有一个LPS状态，即packet spacing，如上图所是。

前面提到LLP的packet主要有两种: SP和LP。一个LP包含了一行图像数据，一个SP则用来表
示一些特殊的用途，主要进行同步，例如将要提到的帧开始(FS)、帧结束(FE)。线开始(LS)
和线结束(LE)则是可选的。

一帧必须以FS开始，以FE结束，中间为帧高度大小个数的LP，每个LP包含一行图像数据。
如下图所示:

![Fig8.one frame on bus](/mipi_csi2/one_frame.png)

图中底部的VVALID、HVALID和DVALID说明了垂直有效和水平有效的时间。

图中开始和结尾的FS和FE为SP；data packet为LP，每个LP由PH(packet header)、Data和
PF(packet footer)组成。PH中包含的字段表明该LP中的data为什么格式的图像数据以及其他
有用字段；PF则包含了包的校验和。LP的字段如下图所示:

![Fig9.long packet structure](/mipi_csi2/lp.png)

每一行的数据包行在LP的data字段，根据不同的格式，其组织方式也不一样。这即为上一章
Pixel/Byte转换层的作用。关于data的格式，可以参考`Chapter 11 Data Formats`。

如RGB565的格式如下:

![Fig10.RGB565 data format](/mipi_csi2/rgb565_data_format.png)


# Linux驱动

在Linux系统中，要使用CSI进行图像传输，还需要对应的驱动配合。这里需要两个驱动的
配置，CSI receiver驱动和CSI sender驱动。

CSI receiver驱动用来控制SoC上的CSI外设，读取CSI总线上的数据并输出到内存或者ISP
上。该驱动通常位于drivers/media/platform/soc_camera。该驱动对上，参与到soc_camera
子系统和v4l2子系统中，成为v4l2的device，以/dev/video接口提供给用户层；对下控制SoC中的CSI
硬件和调用subdev的接口。

CSI sender驱动即为摄像头驱动，即sensor驱动，位于drivers/media/i2c中。该驱动通过
i2c控制sensor，配置参数、启动或停止传输图像，另一方面作为v4l2 device的subdev，
提供接口给receiver驱动调用。

驱动的实现重点在与通过I2C接口对sensor进行配置，并启动和停止传输，了解soc_camera
子系统，将这些操作封装为回调函数提供给上层。

# 总结

本文概括介绍了CSI-2协议，并没有详细的罗列规范中的细节，而是讲解了协议的层次结构，
展现总线上实际数据传输情况，提供一个感性的认识。驱动方面也是概括性地介绍，没有涉
及各个子系统的细节，因为实现细节和内核版本有关，v4l2和soc_camera也一直在进化。
