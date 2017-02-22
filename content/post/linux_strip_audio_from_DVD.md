---
title: linux下从DVD中提取音频
author: zhs
type: post
date: 2009-11-20T12:20:52+00:00
views:
  - 716
categories:
  - tech
tags:
  - linux

---

最近又重温了一边when harry met sally，果然是经典，再多看一遍都不会腻。同时有了想把dvd中的音轨放到ipod中，这样就可在睡觉时候也可以听电影了(并不是针对这个电影里的某一经典段落)，这是因为以前在电驴上下过大话西游的电影音轨。

本来想要换回到windows，用kmp边再看一边边用音频截取的功能录下音轨来的，不过这个方法实在是笨的可以，而且我有不愿意在windows下搞这些东西。难道linux下就没有解决方案吗？google吧。

答案是有的。这边的方案就是mplayer+mencoder。

<!--more-->

作为ubuntu用户，这两个安装就很方便了，不赘述，并保证你能正常播放该DVD，也就是说编码器都OK了。

首先，把DVD放到光驱里(如果是有防拷的正版碟这个办法就不行了，还好我买的是第九区的碟，呵呵)，然后可以在命令行下运行：mplayer dvd://1 。这样的话，应该可以看到播放的窗口程序了，与此同时，可以在终端下看到如下信息：

```text
MPlayer 1.0rc2-4.2.3 (C) 2000-2007 MPlayer Team
CPU: Intel(R) Pentium(R) 4 CPU 3.20GHz (Family: 15, Model: 6, Stepping: 2)
CPUflags: MMX: 1 MMX2: 1 3DNow: 0 3DNow2: 0 SSE: 1 SSE2: 1
Compiled with runtime CPU detection.
mplayer: could not connect to socket
mplayer: No such file or directory
Failed to open LIRC support. You will not be able to use your remote control.
 
Playing dvd://1.
There are 27 titles on this DVD.
There are 16 chapters in this DVD title.
There are 1 angles in this DVD title.
audio stream: 0 format: ac3 (5.1) language: en aid: 128.
audio stream: 1 format: ac3 (stereo) language: zh aid: 129.
audio stream: 2 format: ac3 (stereo) language: ja aid: 130.
audio stream: 3 format: ac3 (stereo) language: en aid: 131.
audio stream: 4 format: ac3 (stereo) language: en aid: 132.
number of audio channels on disk: 5.
subtitle ( sid ): 0 language: en
subtitle ( sid ): 1 language: fr
subtitle ( sid ): 2 language: es
subtitle ( sid ): 3 language: es
subtitle ( sid ): 4 language: in
subtitle ( sid ): 5 language: ja
subtitle ( sid ): 6 language: ja
subtitle ( sid ): 7 language: ko
subtitle ( sid ): 8 language: ko
subtitle ( sid ): 9 language: th
subtitle ( sid ): 10 language: zh
subtitle ( sid ): 11 language: zh
subtitle ( sid ): 12 language: zh
subtitle ( sid ): 13 language: zh
number of subtitles on disk: 14
MPEG-PS file format detected.
VIDEO: MPEG2 720x480 (aspect 3) 29.970 fps 9800.0 kbps (1225.0 kbyte/s)
xscreensaver_disable: Could not find XScreenSaver window.
GNOME screensaver disabled
==========================================================================
Opening video decoder: [mpegpes] MPEG 1/2 Video passthrough
VDec: vo config request - 720 x 480 (preferred colorspace: Mpeg PES)
Could not find matching colorspace - retrying with -vf scale...
Opening video filter: [scale]
The selected video_out device is incompatible with this codec.
Try appending the scale filter to your filter list,
e.g. -vf spp,scale instead of -vf spp.
VDecoder init failed
Opening video decoder: [libmpeg2] MPEG 1/2 Video decoder libmpeg2-v0.4.0b
Selected video codec: [mpeg12] vfm: libmpeg2 (MPEG-1 or 2 (libmpeg2))
==========================================================================
==========================================================================
Forced audio codec: mad
Opening audio decoder: [liba52] AC3 decoding with liba52
Using SSE optimized IMDCT transform
Using MMX optimized resampler
AUDIO: 48000 Hz, 2 ch, s16le, 448.0 kbit/29.17% (ratio: 56000-&gt;192000)
Selected audio codec: [a52] afm: liba52 (AC3-liba52)
==========================================================================
AO: [pulse] 48000Hz 2ch s16le (2 bytes per sample)
Starting playback...
VDec: vo config request - 720 x 480 (preferred colorspace: Planar YV12)
VDec: using Planar YV12 as output csp (no 0)
Movie-Aspect is 1.78:1 - prescaling to correct movie aspect.
VO: [xv] 720x480 =&gt; 854x480 Planar YV12
A: 0.6 V: 0.5 A-V: 0.089 ct: 0.023 10/ 8 ??% ??% ??,?% 1 0
demux_mpg: 24000/1001fps progressive NTSC content detected, switching framerate.
GNOME screensaver enabled.012 ct: 0.132 139/136 6% 0% 1.5% 1 0
 
Exiting... (Quit)
```

如果是附加了-v，则可以得到更多信息，但以上的已经足够了，我们来分析一下：

在 playing dvd://1 下面列出了该dvd的信息，包括有多少的title，多少音轨，多少字幕，视频信息是什么。这里说了，when harry met sally里面有5条音轨，英文en的有三条，中文zh的一条，日文ja的一条，其中第一条还是5.1的，每条音轨后面都有一个id号，即 aid，这个在接下来提取音轨是用来标志你要提取哪条音轨。其他的信息在这里则不关心了。

当然，很多好的dvd都有很多评论音轨的，如果你想要这些音轨，或者不确定要的是不是对的，则可以用：mplayer dvd://1 -aid 128，指定播放的音轨，来听听看是不是你要的。至于这个参数的使用，man 一下就知道了。

确认好了要提取的音轨之后，开始提取了。分两步走。

首先，执行命令

   `$ mencoder dvd://1 -ovc frameno -oac mp3lame -lameopts cbr:br=192 -aid 128 -o novideo.avi`

这里，dvd://1指定要rip的目标；-ovc，表示输出、视频、编码，这里为一个无的意思，因为我们只提取音轨，不做视频转换；-oac，表示输 出、音频、编码，这里用的直接转成了mp3，使用的是lame，如果没装的，装一个先，后面-lameopts表示lamp的参数，为固定码率192，至 于其他的可以参看mencoder的man了，你也可以直接输出为pcm或ac3的格式，只要指定-ovc后面的值就可以了；-aid 128 则是指定要提取的音轨的id；-o 指定输出文件为novideo.avi。

这条命令执行大概输出是这样子的：

```text
1 duplicate frame(s)!
Pos:5569.5s 133551f (97%) 142.46fps Trem: 0min 135mb A-V:0.003 [0:191]
```

可以看到时长，进度，剩余时间都有表示。我这个1:35分钟的电影，在这个老爷机上用了18min了，还是很块的，比起用kmp看着截取实在是&#8230;&#8230;

在得到了novideo.avi之后，执行：

`$ mplayer -dumpaudio novideo.avi -dumpfile when_harry_met_sally.mp3`

运行输出是：

```text
MPlayer 1.0rc2-4.2.3 (C) 2000-2007 MPlayer Team
CPU: Intel(R) Pentium(R) 4 CPU 3.20GHz (Family: 15, Model: 6, Stepping: 2)
CPUflags: MMX: 1 MMX2: 1 3DNow: 0 3DNow2: 0 SSE: 1 SSE2: 1
Compiled with runtime CPU detection.
mplayer: could not connect to socket
mplayer: No such file or directory
Failed to open LIRC support. You will not be able to use your remote control.
 
Playing when_harry_met_sally_novideo.avi.
AVI file format detected.
[aviheader] Video stream found, -vid 0
[aviheader] Audio stream found, -aid 1
VIDEO: [FrNo] 720x480 24bpp 29.970 fps 0.8 kbps ( 0.1 kbyte/s)
Core dumped ：)
 
Exiting... (End of file)
```

意思是从avi文件中吐出音轨来，吐到when\_harry\_met_sally.mp3这个文件里，这样就得到了想要的东西了。完成。

所以说，这个mencoder还是很强大的。事实上，很多win下的转换软件也是靠这mencoder在工作的。等以后有了便携的视频播放器，比如psp之后，估计转换工作会很多和需要的，这样的话，摸熟了mencoder的参数之后，写个脚本配置好参数，就可以直接用了，很好很强大。
