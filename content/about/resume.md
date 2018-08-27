+++
draft = false
description = "resume"
isCJKLanguage = false
date = "2018-05-30T17:47:50+08:00"
title = "Resume"
categories = []
tags = ["resume", "me", "career", "about"]
+++

# Haishan Zhou
--------------------------------------------------------------------------------

- [Auckland, New Zealand](https://www.google.com/maps/place/Auckland)
- <zhssmail@gmail.com>
- [Blog](http://ericnode.info)
- [Github](https://github.com/choueric)
- [Linkedin](https://www.linkedin.com/in/Haishan-Zhou-00263755)

Work as a software developer in embedded linux system with EE background.
Experience in developing linux kernel drivers for various peripheral devices
which are contained in SoC or individual chips communicating with SoC via buses
like I2C. In addition to the kernel part, daily work involves user-space
development in a varity of fileds, including network, video processing and GUI
programming etc.

Embrace open source and on [Github](https://github.com/choueric) host some side
projects, most of which are developed in Golang.

# Technical Skills
--------------------------------------------------------------------------------
- **Languages**: C, C++, Golang, Bash
- **Common development tools**: vim, gcc, make, cmake, git, svn, eclipse
- **Embedded system**:
	- _Linux kernel driver development_: RTC, MTD & flash & eMMC, pinctrl & GPIO,
	  ALSA, framebuffer, WiFi, input, regulator, devcice tree.
	- _Peripheral protocols_: USB, I2C, I2S, SPI, MMC & SDIO, WiFi, MIPI, etc.
	- _Programs_: u-boot, busybox, wpa_supplicant, buildroot
	- Android BSP development
	- Develop OS abstract layer SDK
	- _Processors_: Hi3519, Tegra K1, Tegra X1, DM8107, Baytrail Atom, AM1080,
	  SC2440, AT91RM9200
- **Network**:
	- Socks5 proxy (rfc1928)
	- DHCP client (rfc2131)
	- IP conflict detection (rfc5227)
- **Video & Graphic**:
	- FFmpeg, GStreamer, OpenMAX
	- H264
	- OpenGL
- **Others**:
	- QT
	- freetype

# Open Source Contributions
--------------------------------------------------------------------------------

- [Linux Kernel](https://github.com/torvalds/linux)
- [hugo](https://github.com/gohugoio/hugo)
- [blackfriday](https://github.com/russross/blackfriday)

# Employment History
--------------------------------------------------------------------------------

## Invenco Group Limited
- **Embedded and Application Engineer**
- Aug 2018 - Present
- Auckland, New Zealand

## Magewell Electronics Co., Ltd.
- **Software Developer**
- Nov 2015 - Jun 2018
- Nanjing, China

Responsible for the BSP routines: porting Linux kernel to customized boards,
developed drivers for various hardware, built rootfs and wrote infrastructural
programs to support high performance applications.

Major work includes:

* OS abstract libraries providing unified interfaces to operate general data
  structures and access peripherals.
* Customization of Linux kernels for various products.
* Drivers manipulating peripherals like camera, clock generator, fan
  controller etc.
* Font tool, using freetype library, to convert TTF font file into C code.
* Plugins for GStreamer and FFmpeg to handle video process.

## Mindray Medical International Co., Ltd

- **Software Developer**
- Jul 2011 - Nov 2015
- Shenzhen, China

Involved in devloping complex and stable demanding projects in medical device
industry. Responsible for Linux kernel maintenance, driver development and
team management.

Major work includes:

* Evaluation the stablity and efficiency of data communication via USB on
  Windows Embedded and Linux.
* Development of kernel drivers for AED and monitor products.
* Fixing WiFi connectivity issues and implementing EAP and roaming functions.
* As team leader, managing development, communicating with collegues from 
  other departments and implementing key components in the next-generation
  product.
* Travel to Europe alone for three months to integrate devices from eight 
  manufacturers, like GE and Maquet.

# Education
--------------------------------------------------------------------------------

## Master of Circuit & System
- Southeast University
- Sep 2008 - Jul 2011

## Bachelor of Electronic Science & Technology
- Southeast University
- Sep 2004 - Jul 2008

# Projects
--------------------------------------------------------------------------------

## Pro Gearbox

Pro Gearbox, adopting Xilinx Zynq as processor, efficiently converts HDMI A/V
signals into IP data and acts as NDI source.

Developed MW_SDK, the next generation infrastructural libraries as the OS
abstract layer, which includes not only basic types, data structure, but also
universal interfaces to access various kinds of hardware and user-space device
drivers. The main work includes:

- build system using CMake
- atomic, spinlock, mutex and list modules
- hardware interfaces for I2C, UART, UIO and GPIO
- device drivers for Si5324 and VISCA

Wrote TUI program to convert font by freetype from ttf to bitmap as C array,
which then is used to generate the configuration menu in HDMI output.

Wrote UIO-DMA driver managing the allocation, mapping of four kinds memories
for DMA.

## Stream Art

An encoder reads multiple HDMI inputs and performs rich video processes, such
as scaling, color space conversion, contrast adjustment, etc.

Wrote OpenMAX and OpenGL programs to do benchmark on Jetson TK1 and TX1 for
performance of video encode/decode unit and GPU.

Ported the reference Linux kernel 3.10.40 and u-boot of Nvidia Tegra K1 to
product board and developed kernel drivers for peripherals, such as nct1008.

Developed mwcodec based on TK1 NvMM SDK and then FFmpeg codec plugins.

Created rootfs build system to integrate all components: u-boot, kernel image,
Ubuntu base filesystem and QT.

Customized Android system, including startup tasks, remove unneeded packages,
modifying flash procedure, adding new product device.

## Ultra Stream HDMI

A standalone recoding & streaming encoder, which automatically detects HDMI
input format and performs high-quality H264 conversion.

Assisted kernel development:

- Wrote pinctrl and GPIO drivers.
- Implemented Wake-on-Lan via ethernet transceiver RTL8211F.
- Port kernel drivers for RTC rx-8010, touchscreen gt9147.
- Created GPIO regulators.

## BeneLink

The BeneLink module, an interoperability component, reads information from
external devices, such as ventilators and anesthesia machines, via UART and
converts and uploads them Mindray's monitor.

On a business travel alone to Europe for about 3 months, cooperated with doctors
in hospitals and developers from third party manufacturers to accomplish the
intergration of 8 devices.

## BeneVision N22/N19

It uses Intel Baytrail processor and runs on Linux system which is built by
Yocto. The GUI is based on QT/XWindow stack. In addition to Gigabit ethernet,
it supports 2.4G/5G WiFi connectivity with EAP.

Participated in the pre-research phase of this project. In the developing
phase, as the leader of 5 people embedded BSP team, managed the team work and
communicated with colleagues from other departments.

Besides the management, devlopment work included:

- Ported the Linux kernel to product board
- Customized Yocto to build entire system
- Designed the protocols between the host and external modules,
  including parameter modules via SPI, front pannel via I2C and power module via
  UART
- Implemented the SPI protocol on the host
- Reworked the driver adapter library
- Developed the DHCP client and IP-conflict-detection program

## BeneView T1

This mobile device, when it is put into the dock connecting to a VGA screen,
outputs to the external screen in a larger layout to show more information.
It adopts the TI AM1808 processor and runs Linux kernel 2.6.38.

- Implemented dynamically resolution switch for framebuffer driver
- Worked on the WiFi functions, including EAP authentication, roaming, QoS and
  fixed wpa_supplicant bugs
- Designed and implemented the watchdog system.

## BeneHeart D1

D1 is an AED product using TI AM1808 as processor and running on Linux 2.6.38.

Took over midway of the BSP development:

- Optimized the boot time of u-boot.
- Fixed the pop sound bug in AIC1303 driver.
- Reseached breakpad and applied to product.

## Endeavor

The product uses Intel Atom CPU and Windows Embedded as OS. The application
program is written in C# and WPF. External parameter modules are connected to it
via USB as HID devices. These modules are embedded system running on MCF52223.

- Fixed USB communication bugs with parameter modules
- Investigated USB bugs on Windows and Linux
