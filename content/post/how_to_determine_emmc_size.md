+++
draft = false
date = "2017-06-22T15:13:38+08:00"
title = "如何计算eMMC大小"
description = "how to calculate the capacity of eMMC"
isCJKLanguage = true
categories = ["tech"]
tags = ["emmc", "embedded"]

[blackfriday]
  extensions = ["joinLines"]

+++

# User Area

计算方法其实已经在规范中给出了，参考eMMC 5.0 spec里的段落。首先是:

> 7.3.12 C_SIZE [73:62]
> 
> The C_SIZE parameter is used to compute the device capacity for devices up to 
> 2 GB of density. See 7.4.52, SEC_COUNT [215:212] , for details on calculating 
> densities greater than 2 GB. When the device density is greater than 2GB, the 
> maximum possible value should be set to this register (0xFFF). This parameter 
> is used to compute the device capacity.
> 
> The memory capacity of the device is computed from the entries C_SIZE, 
> C_SIZE_MULT and READ_BL_LEN as follows:
> 
> 	- Memory capacity = BLOCKNR * BLOCK_LEN where BLOCKNR = (C_SIZE+1) * MULT
> 	- MULT = 2 ^ (C_SIZE_MULT+2), (C_SIZE_MULT < 8)
> 	- BLOCK_LEN = 2 ^ READ_BL_LEN, (READ_BL_LEN < 12)
> 
> Therefore, the maximal capacity that can be coded is 4096*512*2048 = 4 GBytes.
> 
> Example: A 4 MByte device with BLOCK_LEN = 512 can be coded by C_SIZE_MULT = 0 
> and C_SIZE = 2047. When the partition configuration is executed by host, device
> will re-calculate the C_SIZE value that can indicate the size of user data area
> after the partition.

其次是

> 7.4.52 SEC_COUNT [215:212]
> 
> The device density is calculated from the register by multiplying the value of
> the register (sector count) by 512B/sector as shown in following equation.
> 
> 	Device density = SEC_COUNT x 512B
> 
> The maximum density possible to be indicated is thus 4 294 967 295x 512B.
> 
> The addressable sector range for the device will be from Sector 0 to Sector 
> (SEC_COUNT-1).
> 
> The least significant byte (LSB) of the sector count value is the byte [212].
> 
> When the partition configuration is executed by host, device will re-calculate
> the SEC_COUNT value that can indicate the size of user data area after the 
> partition.

简而言之，对于容量小于2GB的，采用第一种方法，即:

> 	- Memory capacity = BLOCKNR * BLOCK_LEN where BLOCKNR = (C_SIZE+1) * MULT
> 	- MULT = 2 ^ (C_SIZE_MULT+2), (C_SIZE_MULT < 8)
> 	- BLOCK_LEN = 2 ^ READ_BL_LEN, (READ_BL_LEN < 12)

其中`C_SIZE`, `C_SIZE_MULT`和`READ_BL_LEN`为CSD寄存器中的字段。然而时代在发展，
对于目前使用的eMMC来说，2GB显然都被淘汰了，因此制定了新的计算方法，即:

> 	Device density = SEC_COUNT x 512B

直接使用Extended CSD中的`SEC_COUNT`，更加简单。

# Boot Area

对于Boot Area分区，规范中规定有两个Boot Area分区，大小为128KB的整数倍。通常每个
为4MB，一共8MB。

> 7.4.42 BOOT_SIZE_MULT [226]
> 
> The boot partition size is calculated from the register by using the following
> equation:
> 
>   Boot Partition size = 128Kbytes × BOOT_SIZE_MULT

# RPMP

协议中规定必须有一个RPMP分区，大小为128KB的整数倍，通常为8MB。

> 7.4.77 RPMB_SIZE_MULT [168]
> 
> The RPMB partition size is calculated from the register by using the following
> equation:
> 
>   RPMB partition size = 128kB x RPMB_SIZE_MULT
