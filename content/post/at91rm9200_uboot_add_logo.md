---
title: at91rm9200的uboot里添加lcd驱动
author: zhs
type: post
date: 2009-08-15T12:30:33+00:00
views:
  - 225274
categories:
  - tech
tags:
  - embedded
  - linux

---

为了能够在uboot起来的时候能够驱动s1d13506并显示开机图片，需要在uboot初始化板子的硬件的时候 将lcd显示部分的电路也初始化好。本文中uboot的版本为1.1.2，里面其实已经有了sed13806的驱动代码了，在 drivers/sed13806.c和include/sed13806.h，但只是在板子Total5200和RPXClassic的配置里有包括， 这个可以查下config文件里有没有CONFIG\_VIDEO\_SED13806就可以知道了。这里因为13806和13506并没有差很多，所以直接 就在sed13806的文件基础上修改了。

首先就是要在include/configs/at91rm9200dk.h里面添加相应的宏。

其实这个文件里我并没有添加很多的宏，因为我没有调用uboot为其他平台所写的lcd.c里面或者其他的显示相关的东西，而是自 己在手动添加显示初始化代码，因此在at91rm9200dk.h这个配置文件里并没有出现CONFIG_LCD这类配置宏。

添加的宏有：

```c
#define CONFIG_VIDEO_SED13806
#define CONFIG_VIDEO_SED13806_16BPP
#define CONFIG_NEC_NL644BC20
```

然后到include/sed13806.h中修改FRAME\_BUFFER\_OFFSET、TOTAL\_SPACE\_SIZE和 DEFAULT\_VIDEO\_MEMORY_SIZE等相关的板子空间配置。

在这块板子上：

```c
#define DISPLAY_WIDTH 800
#define DISPLAY_HEIGHT 600
#define SED13806_REG_ADDR 0x30000000
#define FRAME_BUFFER_OFFSET 0x200000
#define TOTAL_SPACE_SIZE 0x1400000
#define DEFAULT_VIDEO_MEMORY_SIZE 0x140000 //其实和上面的宏重复了
```

至于寄存器的偏移量的宏定义要不要从linux内核里也弄过来，随便了。

在drivers/sed13806.c里面，可以添加对于s1d13506需要的操作函 数。这里主要是对video\_hw\_init这个函数进行改造，因为这个就是将要在uboot初始化过程中被调用来初始化s1d13506的函数了。修改如下:

```c
void *video_hw_init (void)
{
    unsigned int *vm, i;
    printf("*** zhs: drivers/sed13806.c: video_hw_init() ***\n");
    memset (&sed13806, 0, sizeof (GraphicDevice));

    /* Initialization of the access to the graphic chipset
       Retreive base address of the chipset
       (see board/RPXClassic/eccx.c) */
    /* 初始化板子上的相关的io口和ics1523 */
    if ((sed13806.isaBase = board_video_init ()) == 0) {
        return (NULL);
    }

    sed13806.frameAdrs = sed13806.isaBase + FRAME_BUFFER_OFFSET;
    sed13806.winSizeX = board_get_width ();
    sed13806.winSizeY = board_get_height ();

    sed13806.gdfIndex = GDF_16BIT_565RGB;
    sed13806.gdfBytesPP = 2;

    sed13806.memSize = sed13806.winSizeX * sed13806.winSizeY * sed13806.gdfBytesPP;

    /* Load SED registers */
    /* init sed13806&#039;s registers */
    EpsonSetRegs (); /*设置s1d13506的寄存器*/

    /* (see board/RPXClassic/RPXClassic.c) */
    //board_validate_screen (sed13806.isaBase); //zhs: don&#039;t know why do this 

    /*zhs:TODO:show the logo here*/
    //s1d_show_logo(); //zhs  add

    /* Clear video memory */
    /*
     i = sed13806.memSize/4;
     vm = (unsigned int *)sed13806.frameAdrs;
     printf("i is %d, vm is %x\n", i, vm);
     while(i--)
     *vm++ = 0xffffffff;
    */

    //return (&sed13806);
    /*根据uboot初始化函数数组的要求，
     * 规定了如果成功则要返回0 */
    return 0; //zhs_change
}
```

以上这 个函数基本上就完成了对于驱动lcd所需要的硬件ics1523和s1d13506的设置了：其中board\_video\_init()完成 ics1523的设置，EpsonSetRegs()完成13506的设置。

说到board\_video\_init()函数，当然是和板子有关了，所以要添加在board/at91rm9200dk/at91rm9200dk.c里面。这个函数可以仿照用了sed13806的 board/RPXClassic/eccx.c里面的board\_video\_init()来，事实上对s1d13506的配置代码很多都是拷贝这个里 面的。

首先，拷贝static const S1D\_REGS init\_regs[]数组，这个数组定义了13506的寄存器配置，用来初始化的。里面有两个，通过宏来区别，这里只拷贝16bpp的。也可以把宏控制 给去掉了。对于寄存器数组的修改可以参考linux内核里的数组设置。当然了，包含的头文件也要拷贝了。三个宏定义要拷贝，其实 也在sed13806.h里定义了。

然后是board\_video\_init()函数。eccx.c里面的内容全部可以删掉了，因为是对那个 cpu的设置，和这边的板子无关。内容的话拷贝linux源码里面arch/arm/mach-at91rm9200/board-dk.c里面 dk\_init\_video()内的内容。主要是配置IO口、初始化static memory controller和ics1523。但是，本质上虽然是对cpu的寄存器赋值，但是linux风格的赋值和uboot风格的赋值不一样，要改成 uboot的，具体怎么改可以参考这个文件里已有的寄存器赋值代码。这里函数内容如下：

```c
/*-----------------------------------------------------------------------------
 * board_video_init -- init EPSON s1d13506
 *-----------------------------------------------------------------------------
 */
unsigned int board_video_init (void)
{
    /*zhs:copy from linux source tree arch/arm/mach-at91rm9200/board-dk.c*/
    /* NWAIT Signal */
    //at91_set_A_periph(AT91_PIN_PC6, 0);
    (AT91PS_PIO) AT91C_BASE_PIOC-&gt;PIO_IDR = (unsigned int) (1 &lt;&lt; 6);
    (AT91PS_PIO) AT91C_BASE_PIOC-&gt;PIO_ASR = (unsigned int) (1 &lt;&lt; 6);
    (AT91PS_PIO) AT91C_BASE_PIOC-&gt;PIO_PDR = (unsigned int) (1 &lt;&lt; 6);

    /* Initialization of the Static Memory Controller for Chip Select 2 */
    /*at91_sys_write(AT91_SMC_CSR(2), AT91_SMC_DBW_16 
     | AT91_SMC_WSEN | AT91_SMC_NWS_(4) 
     | AT91_SMC_TDF_(1) 
     );*/
    AT91C_BASE_SMC2-&gt;SMC2_CSR[2] = (unsigned int)( (1 &lt;&lt; 13) | (1 &lt;&lt; 7) |
                                          (4 &lt;&lt; 0) | (1 &lt;&lt; 8) ); 

    at91_ics1523_init();
    return (SED13806_REG_ADDR);
}
```

最后返回寄存器的地址是根据调用这个函数的函数video_hw_init的要求了。

同样在这个文件里还要拷贝eccx.c里面剩下的函数：board\_get\_regs(), board\_get\_width(), board\_get\_height()。

但是上面对ics1523的初始化函数at91\_ics1523\_init()在 uboot里面是没有的，这就需要将linux里面的移植到uboot源码里了。

首先拷贝linux源码中arch/arm/mach- at91rm9200/ics1523.c到uboot中board/at91rm9200dk/ics1523.c中，拷贝linux:include /asm/arch/ics1523.h到include/asm/arch-at91rm9200/ics1523.h，同时观察ics1523.h里 面所要用的宏和变量可以还需要拷贝linux里面的头文件at91_twi.h, gpio.h到同目录下。

对 ics1523.h，at91_twi.h和gpio.h不用修改。但是要对ics1523.c进行修改，主要工作还是使得能够使用uboot风格的进行寄存器赋值，修改如下：

```c
/*
 * arch/arm/mach-at91rm9200/ics1523.c
 *
 * Copyright (C) 2003 ATMEL Rousset
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

 /* TWI Errors */
#define AT91_TWI_ERROR (AT91_TWI_NACK | AT91_TWI_UNRE | AT91_TWI_OVRE)
#define AT91C_BASE_TWI 0xFFFB8000

static void *twi_base;

#define chk_io_ptr(x) (void)0
#define raw_writel(v,a) (chk_io_ptr(a), *(volatile unsigned int *)(a) = (v))
#define raw_readl(a) (chk_io_ptr(a), *(volatile unsigned int *)(a))

#define at91_twi_read(reg) raw_readl(twi_base + (reg))
#define at91_twi_write(reg, val) raw_writel((val), twi_base + (reg))

/* -----------------------------------------------------------------------------
 * Initialization of TWI CLOCK
 * ----------------------------------------------------------------------------- */

static void at91_ics1523_SetTwiClock(unsigned int mck_khz)
{
    int sclock;

    /* Here, CKDIV = 1 and CHDIV = CLDIV ==&gt; CLDIV = CHDIV = 1/4*((Fmclk/FTWI) -6) */
    sclock = (10*mck_khz / ICS_TRANSFER_RATE);
    if (sclock % 10 &gt;= 5)
        sclock = (sclock /10) - 5;
    else
        sclock = (sclock /10)- 6;
    sclock = (sclock + (4 - sclock %4)) &gt;&gt; 2; /* div 4 */
    at91_twi_write(AT91_TWI_CWGR, 0x00010000 | sclock | (sclock &lt;&lt; 8));
}

/* -----------------------------------------------------------------------------
 * Read a byte with TWI Interface from the Clock Generator ICS1523
 * ----------------------------------------------------------------------------- */

static int at91_ics1523_ReadByte(unsigned char reg_address, unsigned char *data_in)
{
    int Status, nb_trial;

    at91_twi_write(AT91_TWI_MMR, AT91_TWI_MREAD | AT91_TWI_IADRSZ_1 | ((ICS_ADDR &lt;&lt; 16) & AT91_TWI_DADR));
    at91_twi_write(AT91_TWI_IADR, reg_address);
    at91_twi_write(AT91_TWI_CR, AT91_TWI_START | AT91_TWI_STOP);

    /* Program temporizing period (300us) */
    udelay(300);

    /* Wait TXcomplete ... */
    nb_trial = 0;
    Status = at91_twi_read(AT91_TWI_SR);
    while (!(Status & AT91_TWI_TXCOMP) && (nb_trial &lt; 10)) {
        nb_trial++;
        Status = at91_twi_read(AT91_TWI_SR);
    }

    if (Status & AT91_TWI_TXCOMP) {
        *data_in = (unsigned char) at91_twi_read(AT91_TWI_RHR);
        return ICS1523_ACCESS_OK;
    }
    else
        return ICS1523_ACCESS_ERROR;
}

/* -----------------------------------------------------------------------------
 * Write a byte with TWI Interface to the Clock Generator ICS1523
 * -----------------------------------------------------------------------------*/

static int at91_ics1523_WriteByte(unsigned char reg_address, unsigned char data_out)
{
    int Status, nb_trial;

    at91_twi_write(AT91_TWI_MMR, AT91_TWI_IADRSZ_1 | ((ICS_ADDR &lt;&lt; 16) & AT91_TWI_DADR));
    at91_twi_write(AT91_TWI_IADR, reg_address);
    at91_twi_write(AT91_TWI_THR, data_out);
    at91_twi_write(AT91_TWI_CR, AT91_TWI_START | AT91_TWI_STOP);

    /* Program temporizing period (300us) */
    udelay(300);

    nb_trial = 0;
    Status = at91_twi_read(AT91_TWI_SR);
    while (!(Status & AT91_TWI_TXCOMP) && (nb_trial &lt; 10)) {
        nb_trial++;
        if (Status & AT91_TWI_ERROR) {
            /* If Underrun OR NACK - Start again */
            at91_twi_write(AT91_TWI_CR, AT91_TWI_START | AT91_TWI_STOP);
            /* Program temporizing period (300us) */
            udelay(300);
        }
        Status = at91_twi_read(AT91_TWI_SR);
    };

    if (Status & AT91_TWI_TXCOMP)
        return ICS1523_ACCESS_OK;
    else
        return ICS1523_ACCESS_ERROR;
}

/* -----------------------------------------------------------------------------
 * Initialization of the Clock Generator ICS1523
 * ----------------------------------------------------------------------------- */
int at91_ics1523_init(void)
{
    int nb_trial;
    int ack = ICS1523_ACCESS_OK;
    unsigned int status = 0xffffffff;
    struct clk *twi_clk;

    twi_base = AT91C_BASE_TWI;

    /* Map in TWI peripheral */
    /*
     twi_base = ioremap(AT91RM9200_BASE_TWI, SZ_16K);
     if (!twi_base)
         return -ENOMEM;
     */

    /* pins used for TWI interface */
    //at91_set_A_periph(AT91_PIN_PA25, 0); /* TWD */
    (AT91PS_PIO) AT91C_BASE_PIOA-&gt;PIO_IDR = (unsigned int) (1 &lt;&lt; 25);
    (AT91PS_PIO) AT91C_BASE_PIOA-&gt;PIO_ASR = (unsigned int) (1 &lt;&lt; 25);
    (AT91PS_PIO) AT91C_BASE_PIOA-&gt;PIO_PDR = (unsigned int) (1 &lt;&lt; 25);

    //at91_set_multi_drive(AT91_PIN_PA25, 1);
    (AT91PS_PIO) AT91C_BASE_PIOA-&gt;PIO_MDER = (unsigned int) (1 &lt;&lt; 25);

    //at91_set_A_periph(AT91_PIN_PA26, 0); /* TWCK */
    (AT91PS_PIO) AT91C_BASE_PIOA-&gt;PIO_IDR = (unsigned int) (1 &lt;&lt; 26);
    (AT91PS_PIO) AT91C_BASE_PIOA-&gt;PIO_ASR = (unsigned int) (1 &lt;&lt; 26);
    (AT91PS_PIO) AT91C_BASE_PIOA-&gt;PIO_PDR = (unsigned int) (1 &lt;&lt; 26);

    //at91_set_multi_drive(AT91_PIN_PA26, 1);
    (AT91PS_PIO) AT91C_BASE_PIOA-&gt;PIO_MDER = (unsigned int) (1 &lt;&lt; 26);

    /* Enable the TWI clock */
    /*
     twi_clk = clk_get(NULL, "twi_clk");
     if (IS_ERR(twi_clk))
     return ICS1523_ACCESS_ERROR;
     clk_enable(twi_clk);
     */
    AT91C_BASE_PMC-&gt;PMC_PCER = (unsigned int)(1 &lt;&lt; 12);

    /* Disable interrupts */
    at91_twi_write(AT91_TWI_IDR, -1);

    /* Reset peripheral */
    at91_twi_write(AT91_TWI_CR, AT91_TWI_SWRST);

    /* Set Master mode */
    at91_twi_write(AT91_TWI_CR, AT91_TWI_MSEN);

    /* Set TWI Clock Waveform Generator Register */
    at91_ics1523_SetTwiClock(60000); /* MCK in KHz = 60000 KHz */

    /* ICS1523 Initialisation */
    ack |= at91_ics1523_WriteByte ((unsigned char) ICS_ICR, (unsigned char) 0);
    ack |= at91_ics1523_WriteByte ((unsigned char) ICS_OE, (unsigned char) (ICS_OEF | ICS_OET2 | ICS_OETCK));
    ack |= at91_ics1523_WriteByte ((unsigned char) ICS_OD, (unsigned char) (ICS_INSEL | 0x54));/*0x7F));*/ //wy
    ack |= at91_ics1523_WriteByte ((unsigned char) ICS_DPAO, (unsigned char) 0);

    nb_trial = 0;
    do {
        nb_trial++;
        ack |= at91_ics1523_WriteByte ((unsigned char) ICS_ICR, (unsigned char) (ICS_ENDLS | ICS_ENPLS | ICS_PDEN /*| ICS_FUNCSEL*/));
        ack |= at91_ics1523_WriteByte ((unsigned char) ICS_LCR, (unsigned char) (ICS_PSD | ICS_PFD));
        ack |= at91_ics1523_WriteByte ((unsigned char) ICS_FD0, (unsigned char) 0x3A);//wy /*0x39) ;*/ /* 0x7A */
        ack |= at91_ics1523_WriteByte ((unsigned char) ICS_FD1, (unsigned char) 0x00);
        ack |= at91_ics1523_WriteByte ((unsigned char) ICS_SWRST, (unsigned char) (ICS_PLLR));

        /* Program 1ms temporizing period */
        //mdelay(1);
        udelay(1000);

        at91_ics1523_ReadByte ((unsigned char) ICS_SR, (char *)&status);
    } while (!((unsigned int) status & (unsigned int) ICS_PLLLOCK) && (nb_trial &lt; 10));

    ack |= at91_ics1523_WriteByte ((unsigned char) ICS_DPAC, (unsigned char) 0x03) ; /* 0x01 */
    ack |= at91_ics1523_WriteByte ((unsigned char) ICS_SWRST, (unsigned char) (ICS_DPAR));

    /* Program 1ms temporizing period */
    //mdelay(1);
    udelay(1000);

    ack |= at91_ics1523_WriteByte ((unsigned char) ICS_DPAO, (unsigned char) 0x00);

    /* Program 1ms temporizing period */
    //mdelay(1);
    udelay(1000);

    /* All done - cleanup */
    /*
     iounmap(twi_base);
     clk_disable(twi_clk);
     clk_put(twi_clk);
     */
    //AT91C_BASE_PMC-&gt;PMC_PCDR = (unsigned int)(1 &lt;&lt; 12);

    return ack;
}
```

这样，对于board\_video\_init()的工作就结束了，而对于EpsonSetRegs也通过对寄存器数组的修改完成。这样函数video\_hw\_init()的工作也结束了。剩下的事情就是将这 个函数添加到uboot的初始化函数数组中，等着在启动过程中被调用即可了。

打开文件lib\_arm/board.c，找到 start\_armboot()，可以知道这个函数就是板子的开始函数了，里面有一段代码：

```c
for (init_fnc_ptr = init_sequence; *init_fnc_ptr; ++init_fnc_ptr) {
    if ((*init_fnc_ptr)() != 0) {
        hang ();
    }
}
```

就是调用函数 数组init\_sequence来初始化了，找到该数组，将13506的初始化函数video\_hw_init添加进去，如下：

```c
init_fnc_t *init_sequence[] = {
    cpu_init, /* basic cpu dependent setup */
    board_init, /* basic board dependent setup */
    interrupt_init, /* set up exceptions */
    env_init, /* initialize environment */
    init_baudrate, /* initialze baudrate settings */
    serial_init, /* serial communications setup */
    console_init_f, /* stage 1 init of console */
    display_banner, /* say that we are here */
    dram_init, /* configure available RAM banks */
    display_dram_config,
    video_hw_init, /*zhs: init sed13506*/
    #if defined(CONFIG_VCMA9)
    checkboard,
    #endif
    NULL,
};
```

就可以了，等着被调用了。

以上就完成了对uboot启动后使能lcd驱动电路的工 作，接下来就是在uboot中来使用这部分电路来显示东西了。

首先有个问题，不知道是13506寄存器的设置问题还是其他的问 题，屏幕显示的显存空间不是以linux里面的0x30200000开始的了。经过实验，是从0x30219000这个地址开始的。那么可以在进入 uboot之后，使用命令mw来向显存空间写入数据来查看。

为了显示开机logo，这里并没有使用uboot的CONGIF\_LOGO, CONFIG\_SPALSH等机制来显示，这些都是uboot代码级的，搞不懂，而是另辟蹊径，既然可以在uboot里面直接操作显存，像mw那样，那么就可以使用tftp或者cp.b来将要显示的数据拷贝到显存中，这样就ok了。

首先要准备图片，使用图片软件制作一张bmp，16位的，r5g6b5的图片。制作图片有个问题，不知道是因为bmp图片的格式问题(是由下向上进行扫描的)，需要将要显示的图片进行垂直颠倒才能正常显示在 lcd屏上。然后烧到nor flash中，这里的开始地址是0x10300000,图片的大小为800x600x2 = 960000B，但是图片的大小为960070，为0xea646，暂时就用这个。使用命令

```sh
$ cp.b 10300000 30219000 ea646
```

即可显示图片了 960000 = 0xea600

总结：要完成对uboot的移植，关键是对linux代码和uboot代码的熟悉，以及对芯片相关手册的熟 悉，其实如果不考虑显示芯片的充分应用和提供策略，只是单纯使能显示电路，难度不是很大，因为linux以及atmel官方已经提供了源码参考，而且有时直接对物理地址进行操作。反而是出现的显存空间错位的问题不知道为什么，有时间要调查一下。


# 后续
当时添加这部分的驱动的时候正好在听Garnet Crow的一张专辑，情绪非常亢奋，大脑飞速运转得飞快，并且代码移植和编写的难度刚刚好维持在能不断克服的程度，让这种状态能够一直保持下去，最后本来评估是几天的工作一个晚上就搞定了。貌似后来再没有碰上这种状况了...
