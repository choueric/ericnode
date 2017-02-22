---
title: '[翻译]  12 UNIX / Linux Time Command Output Format Option Examples'
author: zhs
type: post
date: 2013-11-17T03:42:29+00:00
views:
  - 1295
categories:
  - tech
tags:
  - linux
  - translation

---

原文地址如下：

[12 UNIX / Linux Time Command Output Format Option Examples](http://www.thegeekstuff.com/2013/10/time-command-format)

文中主要介绍time的用法。time命令用以调用指定的程序或命令，并在其结束之后给出本次运行消耗的系统资源等统计信息，包括时间、cpu占有率等。对开发者来说十分有用和便利，也说明了unix/linux系统是对开发人员友好的系统^_^。

需要说明的是，在time的man中提到，如果使用的是bash shell，那么调用time需要显式地使用绝对路径，一般是/usr/bin/time，如果只是使用time，那么调用的其实是bash内置的命令。也因此本文中的time都是全路径调用. time的详细说明和全部的参数请阅读man文档。

============================================================================

Linux中的time命令有助于确认执行一条命令所需时间。通过该命令，你可以弄清楚执行一条命令、shell脚本或者其他外部程序所耗费的时间。

默认情况下，time命令执行指定的命令或程序。在结束后，它将资源使用的统计信息输出到标准错误输出，即stderr。

本文将简要介绍time命令提供的一些命令行参数以及格式化选项。

# time命令的基本使用

time命令的调用格式如下：

```sh
$ time [-options] <command arg1 arg2 ..>
```

例如，不带参数运行sleep命令，运行结果如下：

```sh
$ /usr/bin/time sleep 2
0.00user 0.00system 0:02.00elapsed 0%CPU (0avgtext+0avgdata 2288maxresident)k
0inputs+0outputs (0major+172minor)pagefaults 0swaps
```

接下来看下该命令的一些重要的命令行选项。

# 将统计结果输出到文件：-o 选项

该选项会将默认输出到stderr的统计结果重定向到指定的文件中。例如：

```c
$ /usr/bin/time -o time.txt sleep 2

$ cat time.txt
0.00user 0.00system 0:02.00elapsed 0%CPU (0avgtext+0avgdata 2288maxresident)k
0inputs+0outputs (0major+175minor)pagefaults 0swaps
```

# 将统计结果追加到已有文件中：-a 选项

该命令和-o选项一起使用，将输出结果追加到-o指定的文件中，而不会将指定文件的内容覆盖掉。例如：

```sh
$ /usr/bin/time -a -o time.txt sleep 4

$ cat time.txt
0.00user 0.00system 0:02.00elapsed 0%CPU (0avgtext+0avgdata 2288maxresident)k
0inputs+0outputs (0major+175minor)pagefaults 0swaps
0.00user 0.00system 0:04.00elapsed 0%CPU (0avgtext+0avgdata 2288maxresident)k
0inputs+0outputs (0major+176minor)pagefaults 0swaps
```

# 显示CPU占有率：%P 参数

你可以使用-f选项对输出结果进行格式化。该选项可能会覆盖掉环境变量TIME所指定的输出格式。接下来会一一说明-f后能够使用的参数：%P，%M，%S，%e，%E，%C，%Z，%c，%x。

使用%P参数，输出结果中将显示所执行程序的CPU使用率。该数值由user时间加上system时间再除以总运行时间得到。输出中加上了百分号来显示。

```sh
$ /usr/bin/time -f "\t%P CPU Percentage" find / -name my-program.sh
/root/my-program.sh
        82% CPU Percentage
```

在上面的例子中，find命令执行使用了82%的CPU。

# 显示最大占有内存：%M 参数

该参数会给出所执行命令在运行时占有的最大内存数，单位为KB。

```sh
$ /usr/bin/time -f "\t%M Max Resident Set Size (Kb)" find / -name my-program.sh
/root/my-program.sh
        8688 Max Resident Set Size (Kb)
```

在上面的例子中，find命令所使用的最大内存为8688KB。

显示消耗的CPU时间：%S 参数

该参数显示了所执行程序的指令执行在内核态中所耗费的总CPU时间，单位为秒。

```c
$ /usr/bin/time -f "\t%S CPU-seconds" find / -name my-program.sh
/root/my-program.sh
        0.35 CPU-seconds
```

上例中，find命令在内核态运行的总CPU时间为0.35s。

显示真实的流逝时间：%e 参数

该参数能够显示所执行命令消耗的真实时间（即wall clock），单位为秒。

```c
$ /usr/bin/time -f "\t%e Elapsed Real Time (secs)" sleep 2
        2.00 Elapsed Real Time (secs)
```

上例中，显示了sleep命令执行过程中流逝了2秒时间（译：好文艺的说法）。

# 以另一种格式显示真实的流逝时间：%E 参数

和上一个命令一样，只不过显示的格式是[时]:分:秒。

```c
$ /usr/bin/time -f "\t%E Elapsed Real Time (format)" sleep 2
        0:02.00 Elapsed Real Time (format)
```

上例中，sleep运行消耗了0小时、0分和2秒。

# 显示程序名称和命令行参数：%C 参数

该参数将会打印出所执行命令的程序名和命令行参数。

```c
$ /usr/bin/time -f "\t%C (Program Name and Command Line)" find / -name my-program.sh
/root/my-program.sh
        find / -name my-program.sh test_time (Program Name and Command Line)
```

# 显示系统页大小：%Z 参数

该参数将给出系统的页大小，单位为Byte。对于单个系统来说该值是不变的，不过每个系统之间可能会有差异。

$ /usr/bin/time -f "\t%Z System Page Size (bytes)" sleep 2
        4096 System Page Size (bytes)
```

上例中显示了当前系统的页大小为4096Byte。

# 显示上下文切换次数：%c 参数

该参数显示所执行程序运行中被调度的次数（译：各进程分时使用CPU）。

```c
$ /usr/bin/time -f "\t%c Context Switches" find / -name my-program.sh
/root/my-program.sh
        254 Context Switches
```

上例中，find命令执行时发生了254次上下文切换，即被调度了254次（译：不知道包不包括用户态和内核态的切换？）。

# 显示命令的返回值：%x 参数

该参数显示time调用的命令或程序的退出返回值。

```c
$ /usr/bin/time -f "\t%x Exit Status" top1
/usr/bin/time: cannot run top1: No such file or directory
        127 Exit Status
```

上例中显示，top1命令的返回结果为127，即失败，因为top1并不存在。

在time的man中，time命令的返回值有如下情况：

- 如果time命令中指定的命令被调用了，那么time的返回值为该命令执行的返回值。
- 如果指定的命令不存在，则返回值为127。
- 如果指定的命令存在，但是不能被调用（译：例如权限问题），那么time的返回值为126。
- 其他非零的值（1-125）表示其他错误（译：man中有说明）。

最后一点，执行`time`和`/usr/bin/time`是有一些区别的。在之前的一篇文章[time command](http://www.thegeekstuff.com/2012/01/time-command-examples/)中有说明。
