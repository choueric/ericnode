---
title: mac下“远程桌面”访问linux
author: zhs
type: post
date: 2013-10-20T13:35:02+00:00
views:
  - 3690
categories:
  - tech
tags:
  - linux
  - mac

---

有一天，坐在pc机前敲代码，脑袋突然闪过一个高端的画面，然后自我反省：为什么我只能蜷在台式机前噼里啪啦，而不能靠沙发、腿蹬茶几、手捧MBA噼里啪啦呢？

首先MBA没有安装开发环境，但台式机上装着debian，上有全套环境；其次，我只用vim写代码，因此也不需要IDE。这么看来，要制造出高端的画面还是比较容易的：在linux上跑起sshd，然后在mac上直接ssh即可。

<!--more-->

不过有个问题，最近写的是qt程序，还是必须要有图形界面才能查看运行效果。那么就要看下mac上有没有什么”远程桌面“到linux的方法了。当然VNC、RDP这类的就算了，需要在linux上安装相应的服务端程序且配置麻烦（对我而言啦），而且效果也不怎么样。想到前阵子有人发ssh转发X11的推，感觉这个比较靠谱一点。

google之后，挑出这样一篇帖子，较之某些全篇山下只有一条命令和一句“以上”的文章，这个不仅告诉方法，还写了些原理性的东西，非常良心：[Connecting to Remote Linux Desktop via SSH with X11 Forwarding][1]。不过文中对于X Window的C/S架构中谁是server谁是client好像理解有点错了，文后的回复有提到，大家可以借此学习一下。

首先文章说了为什么用要用ssh转发X11：通过该方法，mac得到的只是由linux上的sshd发送的绘图指令而已，实际的绘图操作则由mac本地的X server完成，因此网络传输的数据量较小，不会产生明显延迟。这当然是由于X Window的C/S设计架构决定。要举个栗子的话，就像玩魔兽世界，服务器计算好角色要做的动作，然后将该指令发送给你的本地电脑，再由本地电脑的显卡使用磁盘里的素材进行渲染。这种模式比起VNC传输图像的方法要好太多了。

# linux端

安装ssh server，并确保可以进行X转发。一般查看/etc/ssh/ssh_config中是否有如下几行即可：

```text
ForwardAgent yes
ForwardX11 yes
ForwardX11Trusted yes
```text

同样确认/etc/ssh/sshd_config中是否有如下内容：

```text
X11Forwarding yes
```

不过我的debian 7系统安装好ssh server之后默认就可以使能了。所以说server端的设置非常简单。

# Mac端

既然是属于X Window的数据，那么mac端也需要安装X11。我的系统是10.8.5，Utility中有X11的程序图标，不过点击后说是需要安装&#8230;&#8230; 在安装了一个XQuartz之后，运行终端，在其中输入：

```sh
$ ssh -X zhs@192.168.0.100 gnome-session
```

运行之后提示输入密码。其中，-X表示进行X11转发的选项；zhs为linux上的用户名；IP则为linux主机的IP；gnome-session为本次ssh会话需要运行的程序。因为我的debian是gnome桌面环境，该命令启动了一个完整的gnome会话，也就相当于一个远程桌面了。

如果用一个单独的程序替换掉gnome-session，例如xclock，那么mac本地上只会运行xclock一个程序。这样的效果就如同xclock这个程序是直接在mac本地上运行一样，而不是只出现在远程桌面的那个框子里。这点只用过windows的人应该理解不了吧（黑得漂亮～）。

此外，下面的命令可以让“远程桌面”表现得更像传统意义上的桌面，即将其限定(nest)在一个单独窗口中：

```sh
xnest -geometry 1280x800 :1 & DISPLAY=:1 ssh -X 192.168.0.100 gnome-session
```

[1]: http://forrestbao.blogspot.jp/2008/01/connecting-your-remote-linux-desktop.html
