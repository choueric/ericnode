+++
title = "C11标准库中的atomic原子操作"
draft = false
description = "The atomic operations in standard library in C11"
isCJKLanguage = true
categories = ["tech"]
tags = ["c", "linux", "program", "atomic"]
date = "2018-05-04T13:43:23+08:00"

[blackfriday]
  extensions = ["joinLines"]

+++

# Intro

C11标准也推出了很久，只是对于嵌入式编程，一方面许多嵌入式工具链版本号较低，另一
方面Linux内核编译选项还是c89的标准，以至于很多便利的特性都没用上，头文件还是用
`#ifndef`宏来隔离、局部变量都定义在函数开始处、循环变量不能定义在循环中，更不用
提动态数组了。

C标准和libc库一直在演进，加入了许多新特性，这里说说atomic原子操作。Linux内核
作为操作系统，不可避免的需要内建atomic操作，一方面为了防止在多线程中data race，
另一方面，比起各种锁，atomic开销小很多。关于内核的atomic，有很多文章进行介绍和
说明:

- 内核文档`Documentation/core-api/atomic_ops.rst`
- [C11 atomic variables and the kernel][1]
- [Atomic primitives in the kernel][2]
- [Atomic usage patterns in the kernel][3]
- [Semantics and Behavior of Atomic and Bitmask Operations][4]

需要注意的是，内核中的很多原子操作的语义和C11中的定义是不同的，例如cmpxchg。

# Standard

在C11标准中，首次引入原子操作，正式将其标准化。然而在我现在的系统ubuntu
14.04上，仍然不能使用`man`来查看其相关手册，需要看标准文档。[ansi.org][5]上的文
档估计要$60吧，不过在网上还能免费下载到草案文档[WG14 draft version N1570][6]。
里面`7.17 Atomics <stdatomic.h>`章节中给出了详尽的定义。这里简单的介绍
一下。

首先，定义了所需要引用的头文件`stdatomic.h`。在我的系统上，该头文件并没有在
`/usr/include`目录下，而是`/usr/lib/gcc/x86_64-linux-gnu/4.9/include/stdatomic.h`

插一句题外话，从标准中还可以看到`stdbool.h`，`stdint.h`, `stddef.h`等等头文件，
定义了很多以前标准中没有、然而特别实用的类型，特别是很多C++里的类型。

其次，标准定义了`__STDC_NO_ATOMICS__`宏，用来在编译时检测是否支持stdatomic。同时
还有一系列的宏和函数用来判断各种数据类型在当前的实现中是否支持原子操作，例如
`ATOMIC_CHAR_LOCK_FREE`, `atomic_is_lock_free`。

然后，标准引入了`memory order and consistency`，在不同的memory order下，原子操作
的效率和严格性不尽相同，具体可以看[这里][7]和[这里][8]。

同时，标准定义了许多原子数据类型，例如`atomic_char`, `atomic_int`, `atomic_size_t`。
必须使用这些数据类型，因为其类型内部可能包含其他数据来保证原子性操作。

初始化原子变量可以使用如下函数，但**不保证原子性**(当然一般也不会在多线程中进行初始
化):

- ATOMIC_VAR_INIT
- atomic_init
- ATOMIC_FLAG_INIT

操作原子变量则使用如下函数，**保证原子性**:

- atomic_store
- atomic_load
- atomic_exchange
- atomic_compare_exchange_strong, atomic_compare_exchange_weak
- atomic_fetch_add, atomic_fetch_sub, atomic_fetch_or, atomic_fetch_xor, atomic_fetch_and
- atomic_flag_test_and_set
- atomic_flag_clear

以上函数还都有`xxx_explicit`版本，多出一个`memory_order`参数，用来显示指定order。

# gcc

在C11之前，gcc对原子操作的支持是通过builtin函数实现的，即`__sync`前缀的函数。后
来修改为`__atomic`前缀。

在C11发布之后，gcc通过`stdatomic.h`提供标准接口。其实如果查看gcc的`stdatomic.h`
，可以发现里面的函数都还是由`__atomic`的builtin函数来实现的。

gcc在`4.9`版本之后才正式、完备的支持stdatomic，在编译命令中加上`-std=c11`或
`-std=gnu11`即可。如果是之前的版本，那只能使用builtin函数了。

关于gcc的atomic情况，可以[gcc的wiki页][9]，里面包含很多有用的链接。

# Example & Docs

我写了一个简单的[测试程序][14]，启动偶数个线程，每个线程循环固定次数对同一个
atomic_int变量操作，一半进行加一操作，另一半进行减一操作。

另外，文章[C11 Lock-free Stack][13]详细地讲解了如何使用C11 atomic实现一个无锁的
stack数据结构，深入浅出，很值得读一读。

除了以上简单的介绍之外，网上还有很多对c11 atomic的不同角度介绍和分析的文章:

- [An implementation of the C11 <stdatomic.h> interface][10]
- [Toward a Better Use of C11 Atomics – Part 1][11]
- [Toward a Better Use of C11 Atomics – Part 2][12]


[1]: https://lwn.net/Articles/586838/
[2]: https://lwn.net/Articles/695257/
[3]: https://lwn.net/Articles/698315/
[4]: https://www.kernel.org/doc/html/v4.12/core-api/atomic_ops.html
[5]: http://webstore.ansi.org/RecordDetail.aspx?sku=INCITS%2FISO%2FIEC+9899-2012
[6]: http://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf
[7]: http://en.cppreference.com/w/cpp/atomic/memory_order
[8]: https://gcc.gnu.org/wiki/Atomic/GCCMM/AtomicSync
[9]: https://gcc.gnu.org/wiki/Atomic
[10]: http://stdatomic.gforge.inria.fr/
[11]: https://developers.redhat.com/blog/2016/01/14/toward-a-better-use-of-c11-atomics-part-1/
[12]: https://developers.redhat.com/blog/2016/01/19/toward-a-better-use-of-c11-atomics-part-2/
[13]: https://nullprogram.com/blog/2014/09/02/
[14]: https://github.com/choueric/tools/tree/master/C/utils/atomic
