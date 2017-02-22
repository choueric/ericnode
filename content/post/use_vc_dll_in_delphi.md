---
title: Delphi中调用VC编写的DLL内对象
author: zhs
type: post
date: 2008-11-10T03:55:40+00:00
views:
  - 2872
categories:
  - tech
tags:
  - delphi

---

Delphi以其独特的面向控件的开发方式、强大的数据库功能以及快速的编译技术，使得它自发布起即格外引人注意。随着Delphi 3提供丰富的Internet应用，Delphi日益成为最重要的软件开发工具之一，吸引了许多原Visual Basic、Foxpro、dBase甚至C++的程序员，而这些程序员使用Delphi时需要解决的一个重要问题就是怎样利用他们原有的代码。本文将介绍Delphi与C++程序集成的方法，包括：

1. Delphi与C++之间函数的共享
2. 代码的静态链接和动态链接
3. 对象的共享
4. 函数的共享

<!--more-->

# 函数相互调用

在Delphi中调用C++函数与C++调用Delphi函数相当直接，需要注意的是，Delphi 1默认的函数调用方式是Pascal方式，Delphi 2、Delphi 3的默认方式则是优化的cdecl调用方式，即register方式。要在C++与Delphi程序之间实现函数共享，除非有充分的原因,否则应该使用标准系统调用方式，即stdcall方式。为了使C++编译器不将函数标记为&#8221;mangled&#8221;，使Delphi编译器误认为函数是采用cdecl调用方式，应该在C++代码中，以extern &#8220;C&#8221;说明被共享的函数，如例所示：

原型说明：
  
在C++中：

<pre class="brush: cpp; gutter: true">extern "C" int _stdcall TestFunc();</pre>

在Delphi中：

<pre class="brush: delphi; gutter: true">function TestFunc:integer; stdcall;</pre>

调用语法：
  
在C++中:

<pre class="brush: cpp; gutter: true">int i = TestFunc();</pre>

在Delphi中:

<pre class="brush: delphi; gutter: true">var i:integer;
 …
 begin
 …
 i:=TestFunc;
 …
 end;</pre>

共享函数的参数必须是两种语言都支持的变量类型，这是正确传递参数的前提。诸如Delphi的currency、string、set等变量类型，在 C++中没有相对应的变量类型，不能被用作共享函数的参数。可以用PChar类型以值参的方式传递字符串指针，这时用户必须注意字符串空间的回收。

Delphi语言中的变参应被说明成C++中相应变量类型的引用形式，如下：

在Delphi中：

<pre class="brush: delphi; gutter: true">function TestFunc(var i:integer):integer;</pre>

在C++中:

<pre class="brush: cpp; gutter: true">int TestFunc(int &i);</pre>

#  **代码链接**

在Delphi与C++之间实现代码链接可采用静态链接或动态链接的方式。

## **1. 静态链接方式**

如果C++程序本身的代码量很小，而且无需担心与C运行库会有交互过程，一般可选用静态链接方式，即把Delphi与C++的目标文件(*.OBJ)链接成最终的可执行文件。具体的方法是使用{$L}编译指令，使Delphi编译器自动读取指定目标文件，说明如下:

<pre class="brush: text; gutter: true">function TestFunc:integer;stdcall;
{$L TestFunc.OBJ}</pre>

##  **2.动态链接方式**

如果C++代码已经相当全面或自成一个完整的子系统，代码量很大，或者用到了C运行库，在这种情况下，应该使用动态链接库(DLL)的方式。此时，在两种语言的源代码中应做如下说明：

在C++中:

<pre class="brush: cpp; gutter: true">int stdcall export TestFunc();</pre>

在Delphi中:

<pre class="brush: delphi; gutter: true">function TestFunc:integer; stdcall;
external ‘TestFunc.DLL’;</pre>

# 对象的共享

在C++与Delphi之间的对象共享主要体现在对象方法(Method)的共享方面，这种共享可分为两个层次：对象(Object)级共享与类 (Class)级共享。

要实现对象级共享，程序设计语言需具备两个前提条件：

  1. 能够定义指向由另一语言创建的对象的指针;
  2. 可以访问由指针确定的对象中的方法。

要实现类级的共享，则还需考虑：

  1. 能够创建由另一种语言定义的类的实例;
  2. 可以从堆中释放一个实例所占用的空间;
  3. 派生新的类。

以下介绍在Delphi与Borland C++之间实现对象共享的方法。

##  **1. C++共享Delphi对象**

要实现从C++调用Delphi对象，首先要在Delphi单元的接口部分以及C++的头文件中说明需要共享的对象的接口，在对象接口中定义该对象包含哪 些属性与方法,并说明可供共享的部分。对象的共享，关键在于方法的共享。在Delphi语言中，要使一个对象可以被共享，可以把它说明为两个接口部分，暂称为&#8221;共享接口&#8221;与&#8221;实现接口&#8221;。其中共享接口指明对象中哪些方法可被另一种语言所共享；实现接口则继承共享接口，并且在单元实现部分针对实现接口中的方法定义具体的实现。要定义一个可供C++共享的Delphi对象，共享接口的说明应注意：

  1. 在Delphi程序里，要共享的方法必须被说明为抽象(abstract)，而且虚拟(virtual);
  2. 在C++程序里，必须用关键字&#8221;virtual&#8221;及&#8221;=0&#8243;后缀，把从Delphi共享的方法说明成&#8221;pure virtual&#8221;;
  3. 共享的对象方法必须在两种语言里都被说明成相同的调用方式，即使用标准系统调用方法stdcall

下面,举例说明这些规则，假设有这样的一个Delphi对象:

<pre class="brush: delphi; gutter: true">TTestObject = class
    procedure Proc1(x:integer);
    function Func1(x:integer):PChar;
    procedure Proc2;
    function Func2:integer;
end;</pre>

如果C++程序需要共享其中的方法Proc1、Func1，需要把上述说明修改成以下形式：

<pre class="brush: delphi; gutter: true">STestObject = class
    procedure Proc1(x:integer); virtual; abstract; stdcall;
    function Func1(x:integer); virtual; abstract; stdcall;
end;

TTestObject = class(STestObject)
    procedure Proc1(x:integer);
    fuction Func1(x:integer):PChar;
    procedure Proc2;
    fuction Func2:integer;
end;</pre>

在C++程序中做如下对象原型说明:

<pre class="brush: cpp; gutter: true">class STestObject {
    virtual void Proc1(int x)=0;
    virtual char *Func1(int x)=0;
};</pre>

为了能在C++中成功地访问Delphi定义的类， Delphi接口说明时必须包含一个可共享的&#8221;制造函数(Factory Function)&#8221;CreateTestObject，该制造函数可被定义在动态链接库或目标文件(.OBJ)中，例如:

<pre class="brush: delphi; gutter: true">Library TestLib;
exports CreateTestObject;
function CreateTestObject:STestObject; stdcall;
begin
    Result:=TTestObject.Create;
end;
…
end.</pre>

经过这样的处理，现在可在C++程序中使用这个由Delphi定义的对象，调用方式如下:

<pre class="brush: cpp; gutter: true">extern "C" STestObject stdcall *CreateTestObject();
void UseTestObject(void) {
    STestObject *theTestObject=CreateTestObject();
    theTestObject-&gt;Proc1(10);
    Char *str=theTestObject-&gt;Func1(0);
}</pre>

当调用制造函数CreateTestObject时，实际上已经在Delphi一侧占用了一个对象实例的空间，C++程序在针对该对象的所有处理完成后必须考虑释放这一空间，具体的实现可在Delphi中定义一个类，如上述Proc1的共享方法Free，以此来完成这一任务:

<pre class="brush: delphi; gutter: true">STestObject=class
    procedure Proc1(x:integer); virtual; abstract; stdcall;
    function Func1(x:integer); virtual; abstract; stdcall;
    procedure Free; virtual; abstract; stdcall;
end;
…
implementation
…
procedure TTestObject.Free;
begin
…
end;
…
end.</pre>

## **2.Delphi共享C++对象**

通常，序员会考虑使用Delphi来编制用户界面，所以Delphi代码调用C++代码似乎显得更加实际些。其实，Delphi共享C++对象的实现方法与上述C++共享Delphi对象非常相似。

用同样的共享接口与实现接口说明方法来定义C++的类:

<pre class="brush: cpp; gutter: true">class STestObjedt {
    virtual void Proc1(int x)=0;
    virtual char *Func1(int x)=0;
 };
class TTestObjedt :public STestObject {
    void Proc1(int x);
    char *Func1(int x);
    void Proc2();
    int Func2();
    void Free();
};</pre>

然后实现这些方法。同样地，C++对象需要一个与之对应的制造函数，这里以DLL为例

<pre class="brush: cpp; gutter: true">stdcall export *CreateTestObject() {
     return (STestObject *) new TTestObject.Create;
}</pre>

Delphi代码可以通过调用制造函数CreateTestObject,很容易地在C++中创建实例，获得指向该实例的指针值，并以这个指针值来调用对象中的共享方法。当然，在进行完该对象的相关处理后，千万不要忘了调用Free释放占用的空间。

<span style="color: #ff0000;">以上为转载内容，自己经过实践， 有如下一些经验：</span>

  1.  <span style="color: #ff0000;">在CreateObject中返回的应该为对象指针，然后在Delphi程序中对CreateObject重新声明时， 返回值应该就是STestObject，因为在Delphi中对象本身其实就是对象引用，即为对象指针（有待证明）。</span>
  2. <span style="color: #ff0000;">从CSDN下载的一 个在DLL中调用VC的类对象例子，发现有BUG，即调用myFree会有错误，表示在Delphi中对象变量得到的并不是在DLL中创建的对象的指针 （因为他的CreateObject返回的是对象本身，而这个函数在Delphi中调用会有一个临时变量来进行赋值，所以真正的对象已经丢了）。而且他的 VC是8.0的，我的开不了&#8230;..。我自己修订后的放在附件里。</span>
  3. <span style="color: #ff0000;">我也是因为项目的关系才开始关注这个的。以前项目中只使用了USB传输数据，因此只需要调用USB中DLL的C函数即可完成与USB的数据通信，但是这次换成了PCI传输数据，话说PCI是个主动对象，因此需要调用一个回調函数来取每桢的数据，因此需要的是调用底层用VC编写的DLL中的一个类对象，然后在 Delphi里面用，给他初始化、设置回調函数什么的。经过一番折腾之后，终于是解决了这个问题，调用成功并且正确取得数据。经过这事，确实认为 Delphi界面＋C++底层控硬件是一个很好的方法。界面能够很快的编完，C＋＋也能够方便的控底层，两者并行开发，通过Delphi调用DLL的对象 整合，而且可以作为一个很好的接口方式，高内聚低耦合。</span>

最后附上示例程序：[Delphi\_VC\_DLL][1]

 [1]: /Delphi_VC_DLL.zip
 
 
```text
2008年11月10日。还是很庆幸自己学了delphi，让我从vc和MFC的梦魇中脱离出来，重新了解到编程
原来并不难，造成困难的原因只是微软的开发环境以及对应的编程架构和那些莫名其妙、眼花缭乱的名
词，也让我成为了彻头彻底的微软黑。
```
