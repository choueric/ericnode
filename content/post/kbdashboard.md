+++
date = "2017-02-23T16:19:53+08:00"
title = "Kernel Build Dashboard"
categories = ["tech"]
tags = ["linux", "kernel", "golang", "tools"]
description = "introduction of kbdashboard."

+++

# Overview

This tool (i.e. `kbdashboard`) is used to configure and manage building 
proceedings of multiple linux kernels. It is written in Golang.

Developpers, especially in embedded system, usually need to modify, build and
test more than one linux kernel in different projects. Each project may use one
kernel of specific version and compile with specific toolchain. Some may only
manipulate one kernel but with different build directories according to
different configurations. Anyway, developpers have to remember various
configurations, direcotries and commands.

To make life easier, `kbdashboard`, acting as a wrapper, handles all these
details. It has advantages :

- Run in any directories, no need of changing into the one where the kernel
  source tree is.
- Use individual building directory without affecting the kernel source tree.
- Simple commands to perform various actions from configuring to installing.
- Easy to configure by the json format.
- Colorful shell output.
- Built-in environment variables for installation scrips.

This post describes how to use this tool and some details. The version mentioned
here is `0.2.2-625c543`。

# Build this Tool

First you need a Golang build environment, which is easy to [install][1].

Then do the routines in the source tree :

```sh
$ make
$ sudo make install
```

You will get the executable `kbdashboard` installed in `/usr/local/bin`. In
addition, the bash completion script will be generated and installed in 
`/etc/bash_completion.d`. The Makefile is very simple and can be modified
easily if you want to change the installation places.

If you do not want to setup the building environment, that's fine. You can get
the executable file in [here][2] and generate the completion file.

# How to Use this Tool

## Generate Bash Completion File

If it is your first time to use this tool, you should use the completion file
to make life easier:
```sh
$ kbdashboard completion
$ source kbdashboard.bash-completion
```

From now, you can use the auto-completion feature of bash.

Here are the quick steps:

1. `$ kbdashboard edit`: Edit the configuration and create a kernel profile.
2. `$ kbdashboard config def`: Make default configuration of kernel.
3. `$ kbdashboard config`: Do the menuconfig of kernel.
4. `$ kbdashboard build`: Build kernel image.
5. `$ kbdashboard install`: Invoke the installation script.

## Create a Profile

The configuration file of `kbdashboard` is the core element. Use command:
```sh
$ kbdashboard edit
```
to create and/or modify it. Its path is `$HOME/.kbdashboard/config.json`. For
the first time, `kbdashboard` will create a default configuration file and open
it using `vim`. The template contains only one kernel profile with, apparently,
invalid values:

```json
{
        "color": true,
        "debug": false,
        "editor": "vim",
        "current": 0,
        "profile": [
        {
                "name":"demo",
                "src_dir":"/home/user/kernel",
                "arch":"arm",
                "cross_compile":"arm-eabi-",
                "target":"uImage",
                "build_dir":"./_build",
                "defconfig":"at91rm9200_defconfig",
                "dtb":"at91rm9200ek.dtb",
                "mod_install_dir":"./_build/mod",
                "thread_num":4
        }
        ]
}
```

Except `profile`, other configurations are global:

- `color`: Colorize the output or not.
- `debug`: Switch debug output on or off.
- `editor`: Specify text editor used by `edit` command.
- `current`: Current profile index. 

The `profile` array contains the profiles of kernels. Among one profile's
options, only two are mandatory:

- `name`: profile name.
- `src_dir`: directory path of the kernel source tree.

Other options can be empty and will be substituted with default value during
building.

- `arch`: architecture name, corresponding to the `ARCH`.
- `cross_compile`: prefix of toolchain, corresponding to the `CROSS_COMPILE`.
- `target`: target of kernel image.
- `build_dir`: building directory, corresponding to `O`. If not absolute, it is 
  relative to the `src_dir`.
- `defconfig`: kernel's default configuration in `arch/$arch/configs`.
- `dtb`: the name of target DTB file.
- `mod_install_dir`: directory to install modules, corresponding to
  `INSTALL_MOD_PATH`. If not absolute, it is relative to the `src_dir`.
- `thread_num`: number of thread used to compile, corresponding to '-j' option.

After editing, use command `list` to see the result:
```sh
$ kbdashboard list
```

Use `choose` to set it as the current profile:
```sh
$ kbdashboard choose demo
or
$ kbdashboard choose 0
```

The current profile is marked by a red (if `color` is true) asterisk in the
output of `list`, with which other commands handle.

## Configure Kernel

Before comipling the kernel, you should configure it. First, make the default
configuration:
```sh
$ kbdashboard config def
```

It will use the `defconfig` configuration and generate `.config` in the
building directory.

Then, do the menuconfig, which is the default behaviour of command `config`:
```sh
$ kbdashboard config
or
$ kbdashboard config menu
```

Finally, if you want to save the result configuration, use command:
```sh
$ kbdashboard config save
```

It will update the configuration file `arch/$arch/$defconfig`.

## Build Kernel

To generate the kernel image, use command `build` whose default subcommand is
`image`:
```sh
$ kbdashboard build
or
$ kbdashboard build image
```

Command `build modules` is used to compile driver modules and install them into
directory `mod_install_dir`:
```sh
$ kbdashboard build modules
```

For some platforms, such as ARM, DTB file is also needed. Use command `build dtb`
to compile DTB and install it into `build_dir`:
```sh
$ kbdashboard build dtb
```

## Install Kernel

Use command `install` to invoke installation script written by the users:
```sh
$ kbdashboard install
```

There is no such script at the beginning, so this command will create an
empty script with name as `'profileName'_install.sh` in `$HOME/.kbdashboard`
and open it using the `editor`. After editing, it will be invoked by this the
command.

In installation script, there are some built-in environment variables that are
helpful:

- `KBD_COLOR`: global, colorful ouput switch.
- `KBD_DEBUG`: global, debug output switch.
- `KBD_EDITOR`: global, edior name.
- `KBD_CURRENT`: global, current profile index.
- `KBD_NAME`: profile, name.
- `KBD_SRC_DIR`: profile, source directory.
- `KBD_ARCH`: profile, archetect.
- `KBD_CC`: profile, cross compiler.
- `KBD_TARGET`: profile, build target.
- `KBD_BUILD_DIR`: profile, build directory.
- `KBD_DEFCONFIG`: profile, default config name.
- `KBD_DTB`: profile, DTB target name.
- `KBD_MOD_DIR`: profile, modules install directory.
- `KBD_THREAD_NUM`: profile, thread number.

For example, if you want to copy your resulted uImage into a directory, which 
is maybe your tftp directory, in your script you can write:
```sh
cp -v $KBD_BUILD_DIR/arch/arm/boot/uImage ~/tftp
```

If user want to modify the script, use command `edit install`:
```sh
$ kbdashboard edit install
```

It is common to use a user-defined installation script in embedded development.
But for PC environment, using command `make install` and `make modules_install`
may be more general and useful.

You can call script using different parameters so that it can do different jobs
each time. For example, to install image, modules and dtb:
```
$ kbdashboard install image
$ kbdashboard install modules
$ kbdashboard install dtb
```

It is up to you to write any things in your own script.

# Command Details

## help

Command `help` can show the supported commands and this is the default behavior
of this program. To see the list of commands:
```sh
$ kbdashboard
or
$ kbdashboard help
```

`help` can also show more detialed usage of specific command. For example
command `build`:
```sh
$ kbdashboard help build
```

## list

`list` will list all kernel profiles and their information. The current profile
is marked by a red asterisk. Be default, it outputs only main information.

Options:

- `-v`: show all information of profiles.

## choose

This command is used to set the current profile by name or index. For example:
```
$ kbdashboard choose 0
$ kbdashboard choose test
```

## edit

It uses `editor` to open configuration file of `kbdashboard` or installation
scripts for editing.

Tool's configuration file and installation scripts are in the same directory
`$HOME/.kbdashboard`.

sub-commands:

- `profile`: edit the tool's configuration file. It is the default behaviour.
- `install`: edit the installation script of current profile.

## config

This command is used to configure the kernel of current profile.

sub-command:

- `menu`: Same as `make menuconfig`. It is the default sub-command.
- `def`: Same as `make xxxx_defcofig`, which is specified by `defcofig`.
- `save`: Same as `make savedefconfig`.

## build

Build various targets of the current kernel. 

- `image`: build kernel image. It is the default sub-command.
- `modules`: build and install driver modules.
- `dtb`: build DTB file specified by `dtb`.

## install

This command is used to invoke the installation script of the current profile.

This script is in the same directory of the configuration file. If it does not
exist, a new script will be created and opened with `editor`. Users can use
command `edit install` to modify this script afterwards.

The parameters in the command line will be transferred into script. For example:
```
$ kbdashboard install arg1 arg2
```

arg1 and arg2 will become the parameters of the installation script.

## make

This command is imported in case complex wrapper commands can not meet all
requirements and acts as a straightforward wrapper of all targets of kernel.

For example, the command of making default configuration `$ make ARCH=arm bcm_defconfig`
is: 
```sh
$ kbdashboard make bcm_defconfig
```

## version

This command shows the version information consisted of version number, build
time and git information(commit ID and branch name):
```sh
$ kbdashboard version
Version    : 0.2.0
Build time : 2017-02-23:15:07:44
Git Commit : 31c1e9e@master
```

## completion

This command does nothing with kernel building instead of generating a bash
completion file. Copy this file to somewhere (e.g. ~/.kbdashboard-completion)
and then `'$ source ~/.kbdashboard-completion`.

# LICENSE
The GPLv3 License. See `LICENSE.md` file for more details.

[1]: https://golang.org/doc/install
[2]: https://github.com/choueric/kbdashboard/releases
