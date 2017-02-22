---
title: 如何在linux内核启动时添加显示图片
author: zhs
type: post
date: 2011-01-20T14:30:00+00:00
views:
  - 828
categories:
  - tech
tags:
  - embedded
  - linux

---

内核版本为2.6.30.4

为了实现了在linux内核启动时不仅仅是只显示一个静态的全屏logo， 而是显示能够表示内核正在启动的进度条，因此需要能够在启动过程中直接操纵framebuffer的功能。 而进度条则可以很简单的使用多次贴图来实现。

既然在启动时能够显示logo，那么按照自己的要求来贴图也就是可能的。关于logo的显示可以参考fbmem.c和logo.c文件。

在fbmem.c中fb\_prepare\_logo()调用logo.c中的fb\_find\_logo()获得struct linux_logo指针，该结构体中包含了logo显示的数据和各种参数如高宽。

然后fbmem.c中fb\_show\_logo()函数中调用fb\_show\_logo\_line()进行实际的显示操作。不需要管fb\_show\_extra\_logos()，一般这个函数不会有用处的。

在fb\_show\_logo\_line()函数中，根据struct linux\_logo中的数据，主要是clut信息，设置好fb\_info中的调色板；其次创建一个struct fb\_image结构体，该结构体为实际用于显示的变量。将fb\_image的数据指向linux\_logo中的数据，然后设置到fb\_image的显示位置和高宽，最后调用函数fb\_do\_show\_logo()。

fb\_do\_show\_logo()中实际上是调用fb\_info中的fb\_ops的fb\_imageblit()函数将fb_image表示的图像写入到framebuffer中，然后显示出来。

至此，一个logo的显示便完成了。由此看出，如果要显示自己的图像，需要准备和设置的东西包括：图像数据、设置fb_image的各个参数以及设置调色板。

图像数据的获得和自制linux的logo的过程一样，在获得ppm文件之后，通过内核编译过程生成.c文件。该文件中有表示实际数据的数据以及表示clut信息的数据，这两个数组都会在后面使用到。 里面还有一个struct linux\_logo结构体，该结构体的信息可以用来建立后面需要显示的每个图像的struct linux\_logo变量。 数据用来显示，而clut数据用来设置调色板。这里在logo.c中定义如下：

```c
/* 显示数据 */
static unsigned char own_image_data0[] __initdata = {
     ......//太多了，省略
};
 
/* clut信息 */
static unsigned char own_image_clut224_clut[] __initdata = {
     0xff, 0xff, 0xff, 0xed, 0xed, 0xed, 0x87, 0x87, 0x87, 0xdb, 0xdb, 0xdb,
     0x64, 0x64, 0x64, 0x77, 0xa4, 0xd1, 0x28, 0x70, 0xb6, 0x17, 0x64, 0xb0,
     0x21, 0x6b, 0xb3, 0x29, 0x70, 0xb6
};
```

然后在logo.c文件中建立struct linux_logo变量， 根据logo本身的格式将该变量的各个参数设置好，如下：

```c
/* linux_logo */
static struct linux_logo own_image_clut224 = {
     .type    = LINUX_LOGO_CLUT224,
     .width    = 182,
     .height    = 32,
     .clutsize    = 10,
     .clut    = own_image_clut224_clut,
     .data    = own_image_data0
};
```

在建立struct fb_image变量，同样设置好，如下：

```c
/* fb_image */
static struct fb_image own_images[OWN_IMAGE_NUM] = {
     .dx = OWN_IMAGE_DX,  //左上角坐标
     .dy = OWN_IMAGE_DY,
     .width = OWN_IMAGE_WIDTH,
     .height = OWN_IMAGE_HEIGHT,
     .depth = OWN_IMAGE_DEPTH,
     .data = own_image_data0,
};
```

之后在logo.c中设置必要的变量和接口函数，如下：

```c
static struct fb_info *own_fb_info;    //保存fb_info信息
/* 设置fb_info */
void own_set_fb_info(struct fb_info *info)
{
    own_fb_info = info;
}
EXPORT_SYMBOL_GPL(own_set_fb_info);
 
/* 获得保存的fb_info */
struct fb_info *own_get_fb_info()
{
    return own_fb_info;
}
EXPORT_SYMBOL_GPL(own_get_fb_info);
 
/* 获得linux_logo */
struct linux_logo *own_get_image_logo()
{
    return &own_image_clut224;
}
EXPORT_SYMBOL_GPL(own_get_image_logo);
 
/* 获得fb_image */
struct fb_image *own_get_image()
{
    return &own_images;
}
EXPORT_SYMBOL_GPL(own_get_image);
```

注意的是，需要把这些接口函数的声明放到linux_logo.h中，然后在需要调用这些接口函数的文件文件中包含该头文件即可。

接下来，在fbmem.c添加一个执行显示图像的函数。 之所以放在该文件中，是因为可以方便的调用一些本地函数。添加的函数如下：

```c
/* 显示logo.c中指定的图像 */
void own_show_image()
{
    u32 *palette = NULL, *saved_pseudo_palette = NULL;
    struct fb_image *pimage;
    struct linux_logo *logo;
    struct fb_info *info;
    
    info = own_get_fb_info();
    logo = own_get_image_logo();
    pimage = own_get_image();
            
    palette = kmalloc(256 * 4, GFP_KERNEL);
    if (palette == NULL)
        return;
    fb_set_logo_truepalette(info, logo, palette);
    saved_pseudo_palette = info-&gt;pseudo_palette;
    info-&gt;pseudo_palette = palette;
 
    fb_do_show_logo(info, pimage, FB_ROTATE_UR, 1);

    kfree(palette);
    if (saved_pseudo_palette != NULL)
        info-&gt;pseudo_palette = saved_pseudo_palette;
}
EXPORT_SYMBOL(own_show_image);
```

要将该函数的声明放到include/linux/fb.h中，以便其他文件调用。

该函数其实是fb\_show\_logo_line()的简化版。调用了logo.c中的几个接口函数来显示。

另外在fbmem.c文件中的fb\_show\_logo()的最后添加logo.c中的own\_set\_fb\_info()函数，以便在确定framebuffer能使用之后获得有效的fb\_info信息。

至此，对图像的显示便完成了，只需要在需要显示的代码处调用own\_show\_image()即可。

不过此方法存在一些缺点：

* 不够灵活，需要自己在各处添加显示函数，这会造成进度条的前进不均匀。这个可以通过添加定时器struct timer_list来实现定时的贴图。
* 对于uboot和应用程序的启动的时间没有办法控制。
  

# 后续

写这篇的时候算比较早了，但好像直到现在，类似在内核启动过程中显示自定义图片或切换图片显示以达到动态效果的文章还比较少。当然文中实现方法在现在的我看来是略显简单粗暴了点，因为当时也没有太仔细研究fbmem之类的架构。
