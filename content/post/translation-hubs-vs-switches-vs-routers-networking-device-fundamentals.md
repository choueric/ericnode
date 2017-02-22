---
title: '[翻译] Hubs vs Switches vs Routers – Networking Device Fundamentals'
author: zhs
type: post
date: 2013-10-13T14:06:10+00:00
views:
  - 8498
mytory_md_mode:
  - url
categories:
  - tech
tags:
  - network
  - translation

---

<span style="color: #3366ff;">原文地址如下：</span>
  
<span style="color: #3366ff;"><a href="http://www.thegeekstuff.com/2013/09/hubs-switches-routers/?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed:+TheGeekStuff+(The+Geek+Stuff)" target="_blank"><span style="color: #3366ff;">Hubs vs Switches vs Routers – Networking Device Fundamentals</span></a></span>
  
<span style="color: #3366ff;">TheGeekStuff这个网站会介绍很多技术基础相关的东西，特别是Linux部分的。</span>
  
<span style="color: #3366ff;">这篇文章就没有详细说明Hub、交换机和路由器的定义、功能，而是简单地罗列</span>
  
<span style="color: #3366ff;">出三者的差异和关联，浅显易懂。</span>

============================================================================

你所使用的大部分系统可能和hub或者交换机(switch)或者路由器(router)相连，但也许你从来没有想过这些网络设备是如何工作的，以及它们之间的差异。

在本文中，我们将讲解这些网络设备在核心技术上的差异。

如果你对于[OSI通信模型][1]中的分层有了解的话，对理解本文会有很大帮助。

# Hubs

  * Hubs，也叫做中继器（repeater），是工作在一层（layer-1）（即物理层）的网络设备，用以连接各个网络设备，实现相互之间的通信。
  * Hub不能处理二层和三层数据，二层与硬件地址相关，三层与逻辑地址（IP）相关。即是说，Hub不能处理基于MAC地址或IP地址的信息。
  * Hub也不能识别单播、广播和组播数据。
  * Hub所做的只是将数据传递到它上面的每个端口，当然除了该数据的来源端口。
  * Hub工作在半双工模式，也就是说Hub一个时刻要么是在接收数据，要么是在发送数据。
  * 如果Hub所连接的多个设备同时发送，那么会产生碰撞（collision）。
  * 当碰撞发生时，Hub会丢弃这些设备发送的数据，并要求这些设备重新发送。通常，设备在随机的时间定时后重新发送数据给Hub。
  * Hub很容易发生碰撞。并且当越多设备连接到Hub后，碰撞越容易发生，这将导致网络的整体性能下降。

# Switch

  * 交换机是工作在OSI通信模型的二层。
  * 交换机也被称为智能Hub（intelligent hub）。
  * 交换机的操作基于硬件地址，将数据在所连接的设备直接转发。
  * 之所以交换机被称为智能Hub，是因为交换机在自己内存中会建立一个地址表格，用以记录不同的硬件地址以及该地址对应的交换机端口。
  * 交换机被拿来和Hub比较是因为，当刚启动时，它表现得和Hub差不多。假设有三个设备连接到了交换机，分别为devA，devB和devC。在刚启动之后，如果devA向devB发送信息，这时交换机会像Hub一样将该信息向所有端口转发。但是，它还会将devA的硬件地址和对应的端口记录在内部表格中。这就意味着，之后如果任何设备发送数据给devA，那么交换机就会很明确地只发送给对应的端口，而不再是所有端口。当交换机上的通信活动越来越多，这个表格会越完善。特定时间后，交换机就变成了完整形态，一个智能版的Hub。
  * 交换机常被和桥接器弄混。虽然两者很相似，当时交换机转发的是有线数据，并且使用被成为ASIC的硬件电路。
  * 交换机只是全双工数据传输，这个Hub不同。
  * 因为二层协议的帧头不包含网段信息，因此交换机不能在网段间转发数据。这也是为什么交换机不被用在那种被分成多个子网段的大型网络环境中。
  * 交换机使用生成树协议，以避免回环。

# Router

  * 路由器是工作在OSI通信模型三层的网络设备。
  * 因为三层协议用以处理逻辑地址（IP地址），因此路由器可以在不同网段之间转发数据。
  * 有时路由器也被叫做三层交换机（layer-3 switch）。
  * 与交换机比起来，路由器拥有更多特性。
  * 路由器维护着用于转发数据的路由表。
  * 在早期，路由器要比交换机慢，这是因为查询路由表的时间开销相对来说比较高。造成这样的原因是由于需要将数据包全部存入到软件缓冲区之后才能进行后续的操作。
  * 今天，这些操作由硬件完成，因此减少了所需时间。因此路由器也不会比交换机慢了。
  * 路由器比起交换机来，拥有的端口数目要少很多。
  * 路由器通常广域网（Wide Area Networks）中用作网段间转发设备。

如果你刚刚接触网络，理解j<a href="http://www.thegeekstuff.com/2012/08/journey-of-a-packet/" target="_blank">ourney of a data packet in internet</a>和<a href="http://www.thegeekstuff.com/2011/11/tcp-ip-fundamentals/" target="_blank">TCP/IP fundamentals</a>也十分重要。

&nbsp;

 [1]: http://en.wikipedia.org/wiki/OSI_model
