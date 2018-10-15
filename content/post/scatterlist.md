+++
categories = ["tech"]
tags = ["linux", "kernel"]
date = "2018-01-31T11:43:37+08:00"
title = "聊聊scatterlist的chain结构"
draft = false
description = "how scatterlist organised as chain"
isCJKLanguage = true

[blackfriday]
  extensions = ["joinLines"]
+++

最近写一个驱动，涉及DMA内存管理，不可避免的需要了解到scatterlist。网上能够搜到
很多方面的资料，例如[这个][1]和[这个][2]。同时内核源码里scatterlist的实现代码
`include/linux/scatterlist.h`和`lib/scatterlist.c`也不是很长，稍微读读源码也能
对它的原理和使用有更深的理解。这里参考的内核版本为`4.14`。

这里不对scatterlist的原理和使用做解释说明，只是聊聊我自己在看以上材料时比较疑惑
的一点：scatterlist是如何组成链的。

`struct scatterlist`结构体内有一个成员`unsigned long page_link`，头文件中对其有
特别有一段注释进行说明:

```c
/*
 * Notes on SG table design.
 *
 * We use the unsigned long page_link field in the scatterlist struct to place
 * the page pointer AND encode information about the sg table as well. The two
 * lower bits are reserved for this information.
 *
 * If bit 0 is set, then the page_link contains a pointer to the next sg
 * table list. Otherwise the next entry is at sg + 1.
 *
 * If bit 1 is set, then this sg entry is the last element in a list.
 *
 * See sg_next().
 *
 */
```

以上文字说明`page_link`的低两位是用做chain的标识位的，以便将scatterlist链起来。
那么这么多的scatterlist是如何组织起来的呢？这就涉及到`struct sg_table`了。

sg_table的sgl成员为`struct scatterlist`类型指针，指向数组，数组成员类型即是一个
scatterlist内存。数组成员个数则由table的nents成员表示。这是一个典型的数组指针加
成员个数的搭配，如此看来，似乎这样就足够了，为什么还需要chain呢？看看
`sg_alloc_table()`的一段注释：

```c
 *  Description:
 *    Allocate and initialize an sg table. If @nents@ is larger than
 *    SG_MAX_SINGLE_ALLOC a chained sg table will be setup.
```

而SG_MAX_SINGLE_ALLOC的定义如下：

```c
/*
 * Maximum number of entries that will be allocated in one piece, if
 * a list larger than this is required then chaining will be utilized.
 */
#define SG_MAX_SINGLE_ALLOC (PAGE_SIZE / sizeof(struct scatterlist))
```

可以得知，table中sgl数组大小最大为PAGE_SIZE，如果nents个数超过了
SG_MAX_SINGLE_ALLOC，那么就需要使用到chain了。具体实现可以查看
`sg_alloc_table -> __sg_alloc_table`。总的来说，当table中所要包含的scatterlist
的个数没有超过SG_MAX_SINGLE_ALLOC时，例如只有10个，其数组的组织如下图所示:

```
sg_table.sgl -----> +---------+
sg_table.nents=10   | entry 0 |
                    +---------+
                    | entry 1 |
                    +---------+
                    | entry 2 |
                    +---------+
                      ...... 
                    +---------+
                    | entry 7 |
                    +---------+
                    | entry 8 |
                    +---------+
                    | entry 9 |
                    +---------+
```

当个数超过了SG_MAX_SINGLE_ALLOC（假设为10）时，加入为20，其数组的组织如下所示:


```
sg_table.sgl -----> +---------+    +--> +---------+    +--> +---------+
sg_table.nents=20   | entry 0 |    |    | entry 9 |    |    | entry 18|
                    +---------+    |    +---------+    |    +---------+
                    | entry 1 |    |    | entry 10|    |    | entry 19|
                    +---------+    |    +---------+    |    +---------+
                    | entry 2 |    |    | entry 11|    |    | entry 20|
                    +---------+    |    +---------+    |    +---------+
                        ......     |      ......       |
                    +---------+    |    +---------+    |
                    | entry 7 |    |    | entry 16|    |
                    +---------+    |    +---------+    |    
                    | entry 8 |    |    | entry 17|    |
                    +---------+    |    +---------+    |    
                    |   next  | ---+    |   next  | ---+    
                    +---------+         +---------+         
```

上图中，每个next的entry，其pagelink&(~0x3)为下一个数组的首地址，`sg_is_chain`将
返回为真。而最后entry 20为end，其`sg_is_last(sg)`则将返回为真。

不过对于使用者来说，其实不必理会一个sg_table内部是如何链起来各个sg的，使用提供
的API函数就可以访问所有的sg了，例如`for_each_sg()`。

至于为什么需要设置page_size的大小限制呢，我觉得应该是分配一个page作为内存管理的
基本单位，一个page一个page的获取比一下子获取多个连续的page更容易吧。

[1]: (http://www.wowotech.net/memory_management/scatterlist.html)
[2]: (https://lwn.net/Articles/234617/)
