---
title: Delphi中Ole和VBA使用
author: zhs
type: post
date: 2008-06-03T09:37:45+00:00
views:
  - 1069
categories:
  - tech
tags:
  - delphi

---
从网上在这方面学到了很多东西，也是该回报网友的时候了，摘录一段毕设里面的文字，基本上是围绕我的毕设课题写的Delphi中OLE和VBA的融合：

Delphi提供了实现OLE自动化功能的途径，其编译器为此提供了强大的功能，同时VCL也大大简化了开发者所需要执行的操作。为了向自动化提供支持，Delphi提供了一个向导和一个功能强大的类型库编辑器，该编辑器可以支持双接口。而Microsoft Office作为一个典型的OLE Automation服务器，可以在Delphi中被轻松的调用和操作。通过Delphi可以控制Word和Excel提供的强大的编程接口，从而无论是 文件的打开、存盘、打印还是文档中表格的自动绘制都能够实现。<!--more-->

Delphi对Microsoft Office的调用和操作，以Word为例，有以下几种方法：

  1. 通过Delphi的控件TOleContainer，将Word嵌入；
  2. 使用Delphi提供的Servers控件调用Word，使用Word的属性；
  3. 通过真正的Com技术，将Office软件目录中文件MSWORD9.OLB中的类库全部导入Delphi中，利用Com技术编程；
  4. 使用CreateOleObject将启动Word，然后以OLE方式对Word进行控制。

以下是对几种方法的难易程度的判别：

  * 通过Delphi的控件TOleContainer 将Word嵌入：

<p style="padding-left: 30px;">
  这是最简单的OLE嵌入，能够直接将Word文档调用。在Delphi的System组件栏中将TOleContainer添加进程序，在代码中使用 CreatObjectFromFile方法打开文档即可，且可以实现Word编辑界面内嵌在应用程序中。但是，如果使用容器类想要控制Word的属性对 象，必须利用其OleObjec属性，且在使用之前必须用DoVerb激活链接的文档，且编程过程中没有代码提示；
</p>

  * 使用Delphi提供的Servers控件调用Word，使用Word的属性：

<p style="padding-left: 30px;">
  使用Delphi的Servers控件来操纵Word，在编程时Delphi能够实现代码提示，总体上看能够较好的实现Delphi对Word的控制，但 是还有一些Word的功能不能在Delphi中调用（比如自己编写的VBA宏代码）。且实现功能时本来在VBA代码中可选则参数在Delphi调用的时候 必须添加，否则，连编译都不能通过。本方式启动的Word与Delphi程序分属两个窗体。此办法仅能作为一个参考。
</p>

  * 真正的Com技术；

<p style="padding-left: 30px;">
  将Office软件目录中文件MSWORD9.OLB中的类库全部导入Delphi中，利用Com技术编程利用真正的Com技术，将 MsWord9.OLD文件类库导入，然后利用Com技术进行使用。整体上类似使用Delphi的Servers控件，稍微比Servers控件麻烦，优 缺点与Servers控件相同。
</p>

  * 使用CreateOleObject将启动Word，然后以Ole方式对Word进行控制：

<p style="padding-left: 30px;">
  本办法是使用以CreateOleObjects方式调用Word，实际上还是OLE，但是这种方式能够真正做到完全控制Word文件，能够使用Word 的所有属性，包括自己编写的VBA宏代码。与Servers控件和com技术相比，本方法能够真正地使用Word的各种属性，和在VBA中编写自己的代码 基本一样，可以缺省的代码也不需要使用。本方式启动的Word与Delphi程序分属两个窗体。缺点是使用本方法没有Delphi代码提示，所有异常处理 均需要自己编写，可能编写时探索性知识比较多[9]。
</p>

通过以上比较，结合课题中编辑器的功能，最终采用了TOleContainer容器类来实现Delphi对Word和Excel的控制。一方面，使用容器 类，能够将Word和Excel编辑界面嵌入在编辑器中，对使用者来说更方便；另一方面，容器类通过OLE对象同样能够操纵Word和Excel的属性对 象，使得Word文档和Excel文档能够符合应用于LED同步显示的要求。

在Delphi中控制Word和Excel，除了获得其OLE对象之外，还需要了解Word文档和Excel文档的对象模型结构，然后借助于VBA，对其进行有效的控制。

首先，要获得对Word或Excel进行某项操作的VBA代码。在“工具->宏->Visual Basic编辑器”里面就可以看到具体的宏代码，可以直接进行编辑。借助于Visual Basic编辑器的帮助文档可以了解VBA语言的具体对象模型和语句语法。另外，还可以使用录制宏的功能自动生成宏代码。方法是选择“工具->宏 ->录制新宏”，然后执行自己想通过程序实现的功能，如存盘、打印等，此时程序一边执行你要实现功能，一边将相应的操作生成了一个宏，在实现功能 后，可以选择“工具->宏->Visual Basic编辑器”，查看生成的宏代码。这样便可以取得实现某项功能的VBA代码了。

接下来，需要精简宏代码。通常，生成的宏代码有很多语句对要实现的功能来说都是多余的，需要找到真正实现特定功能的代码。此时查看具体的代码，剔除明显没 有用途的代码，然后光标停留在宏上面，按F5执行，看是否实现预想的功能，然后逐步精简，得到最小代码。此步骤可参考Word和Excel的VBA帮助来 判断代码是否有用。

最后就是将相应的VBA代码转化成Delphi代码。一般可以在VBA代码前加上TOleContainer对象的OLE对象即可。例如，改变Word页 面背景色为黑色的代码为：

<pre class="brush: delphi; gutter: true">OleContainer1.OleObject.Application.ActiveDocument.Background.Fill.ForeColor.RGB:=clBlack;</pre>

但是，除了这些简单的VBA转换为Delphi代码之外，还有一些需要注意的地方。首先，VBA中使用的一些枚举常量在Delphi中是没有定义的，例 如，wdGreen，该常量为WdColorIndex枚举常量，代表了字体的颜色为绿色，但是直接应用在Delphi代码中编译器会提示该变量未定义， 这时候就需要查找VBA的帮助文档，找出wdGreen具体的数值，在Delphi代码中直接用该数值赋给相应的对象，查看帮助可知wdGreen的数为11。另外，利用OLE容器类使用VBA对象或方法之前必须激活相应的OLE对象，可以通过TOleContainer的DoVerb方法激活，否则在 未激活状态下使用VBA对象方法会出现“Interface not Supproted”异常。除此之外，微软对Office 2007的VBA对象有所修改，最大的修改便是先前版本中工具栏对象CommandBars被Ribbon（功能区）对象代替，并且两者的操作方法也完全 不同，在具体的编程过程中需要根据所应用的不同软件版本选择不同的代码对Word和Excel进行控制和操作。

借助于OLE和VBA，便可以在Delphi中控制和操作Word和Excel文档。除了实现基本的打开文档、保存文档等操作外，还可以针对LED播放显示的要求，实现文档的背景色、字体颜色、删除添加内容等设置操作的自动化。


```text
这是2008.06.03时写的文章，算是当时做完本科毕业设计之后一篇心得。毕设使用的是Delphi，也算是让
我熟悉了当初和MS在windows平台上互争天下的语言，认识到它在当时能够达到的设计优秀，以及虽然衰落
的可悲。相对于之前学习vc，特别是MFC，这也是我在windows下最舒服的编程经验。当然之后全面转向了
linux更是非常幸运。

即便在现在，虽然Borland已经算是不在了，Delphi也不再红火，Anders Hejlsberg也被MS挖脚做出了
C#，但是Delphi仍然还在使用中，就像Cobol一样。因此在整理旧文时，仍然还是将这个留了下来。
```

