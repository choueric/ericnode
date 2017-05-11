+++
draft = false
description = "an example of awk"
date = "2017-05-11T15:20:10+08:00"
title = "一个awk的例子"
isCJKLanguage = true
categories = ["Tech"]
tags = ["awk", "linux"]

[blackfriday]
  extensions = ["joinLines"]

+++

最近公司弃用svn，全部使用git来进行版本控制，使用gitlab作为服务软件。结果在迁移
以前的Android的git仓库时发现gitlab里面工程名居然不支持"/"和"."，需要转换为"_"。
例如需要将

```text
 <project path="abi/cpp" name="android/platform/abi/cpp-4.1" groups="pdk" />
```
转换为:

```text
 <project path="abi/cpp" name="android_platform_abi_cpp-4-1" groups="pdk" />
```

repo管理文件manifest.xml里的仓库将近500，一一确认、转换实在是个苦差事，自然想要
用程序解决。一开始想用Go写个程序，后来觉得没必要，脚本应该就能搞定，用sed、cut、
grep什么的组合一下，无非就是搜索、替换，然后输出。最后发现awk是最适合做这种事情
的，因为它的行为模式就是"pattern {action}"。

首先，脚本convert.awk内容如下:

```awk
#!/usr/bin/awk -f

{
	if ($1 ~ "<project") {
		gsub(/\//,"_", $3)
		gsub(/\./,"-", $3)
	}
	print $0
}
```

实际执行语句只有四行。脚本执行命令为`convert.awk manifest.xml`。

awk程序读入文件，然后一行一行地处理:

1. `$1 ~ "<project"`。该语句对每行内容进行匹配，判断是不是包含`<project`，如果
   是，则进行转换，否则直接输出。
2. 两个gsub语句对第三字段$3，即name字段，通过正则表达式进行替换操作。
   首先将"/"替换为"_"，然后将"."替换为"-"。
3. 最后输出该行。

不的不说，awk真的是非常适合这样的文本处理，足够强大也足够灵活。依靠其内置机制和
支持的语法，简单几行代码能完成相当复杂度的工作。

如果想要系统的学习awk，可以参考这个中文教程[AWK程序设计语言][1]，翻译自awk作者
写的教材`The AWK Programming Language`。这本书深入浅出，详细地介绍和讲解awk语
言。最后部分的例子十分厉害，让人感受到awk的强大。

[1]: https://github.com/wuzhouhui/awk
