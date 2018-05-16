#########################################################################
# File Name: readme.sh
# Author: maze
# Email: mazema@pateo.com.cn
# Created Time: 2018年02月13日 星期二 10时38分37秒
#########################################################################
=============================================
======---------------------------------======
=============================================

=============================================
======---------------------------------======
=============================================

007:apk安装

    adb可用
    adb install xxxx.apk

    adb不可用
    pm install xxxx.apk [建议xxxx.apk使用绝对路径,给予apk文件777权限]
=============//

008:分区挂载

    adb可用
    adb remount /system

    adb不可用
    mount -o rw,remount /system

=============//

009:进入uboot参数配置界面/初始化参数
    
    [printenv查看一下bootcmd是否正确]

    初始化参数：
        bpram clear
        [有些时候boot啥的烧的有问题了以后，不停的进入recovery。可以确认boot正常的情况下使用这条命令重置启动参数]

=============//

010:进入recovery界面

        reboot recovery
=============//

011:重要文件位置

    "defconfig"
    u-boot配置文件     ----> bootable/bootloader/uboot-imx/configs
    kernel配置文件     ----> kernel_imx/arch/arm/configs/imx_v7_x37_android_defconfig
    
    "BoardConfig"
    文件位置           ----> device/fsl/f0307h/BoardConfig.mk
    
    "init.rc"
    文件位置           ----> device/fsl/f0307h/init.rc[编译过后rename为init.freescale.rc]
                       ----> system/core/rootdir/init.rc
    "device下面的init.rc会在编译的过程中重命名为init.${ro.hardware}.rc"
    [其中的命令执行顺序原则上]
            1.根据on boot/init等分开
            2.根据import先后顺序执行

    "dts"
    设备树             ----> kernel_imx/arch/arm/boot/dts/imx6qp-f0307h.dts
                       ----> kernel_imx/arch/arm/boot/dts/imx6q-f0307h.dts
                       ----> kernel_imx/arch/arm/boot/dts/imx6qp.dtsi
                       ----> kernel_imx/arch/arm/boot/dts/imx6q.dtsi
                       ----> kernel_imx/arch/arm/boot/dts/imx6qdl-f0307h.dtsi
                       ----> kernel_imx/arch/arm/boot/dts/imx6q-pinfunc.h
                       ----> kernel_imx/arch/arm/boot/dts/imx6qdl.dtsi
                       ----> dt-bingdings/interrupt-controller/irq.h
                       ----> dt-bingdings/interrupt-controller/arm-gic.h
                       ----> dt-bingdings/input/input.h
                       ----> dt-bingdings/clock/imx6qdl-clock.h
            dts为板级定义
            dtsi为Soc级定义


        
    "board"
    板子启动代码       ----> bootable/bootloader/uboot-imx/board/freescale/mx6f0307h/mx6f0307h.c

    "Makefile"
    make后缀           ----> build/core/Makefile
    make all;make allpackage;make bootimage;*****

=============//

012:dts解析

    a.kernel_imx/arch/arm/boot/dts/imx6q-pinfunc.h             ----> 定义宏
    b.kernel_imx/arch/arm/boot/dts/imx6qdl-f0307h.dtsi         ----> 设置宏
    c.drivers/pinctrl/freescale/pinctrl-imx.c                  ----> imx_pinctrl_parse_groups[解析宏]
    例如:
    a     #define MX6QDL_PAD_NANDF_CS2__GPIO6_IO15            0x2ec 0x6d4 0x000 0x5 0x0
    b             MX6QDL_PAD_NANDF_CS2__GPIO6_IO15 0x80000000 /* WIFI EN */                  0x2ec 0x6d4 0x000 0x5 0x0 0x80000000
    c             MX6QDL_PAD_引脚名称 __引脚功能描述[用来做啥，gpio,pwm还是其他啥]           mux_ctrl_ofs  |  pad_ctrl_ofs |  sel_input_ofs |  mux_mode             | sel_input   |  pad_ctrl
                                                                                             mux地址       |  pad地址      |  sel_input地址 |mux值tx,rx,pwm,gpio... | sel值       |寄存器配置（上拉电阻、频率等）

                 MX6QDL_PAD_NANDF_CS2__GPIO6_IO16 代表第6组gpio中的第16个gpio口，其中每组gpio有32个
    arch/arm/mach-imx/hardware.h                             ----> IMX_GPIO_NR
                 在驱动中使用gpio_request时，io端口号为IMX_GPIO_NR(6,16)=32*(6-1)+16=176

    [所有关于dts的文档在Documentation/devicetree/bindings/*fsl*]
=============//

015:查看安装apk包名

    pm list package   找到已经安装的包名
    打开应用
    logcat grep 包名  从而确认activity名字
    am start 包名/activity名 打开应用

    例如:安装一汽车展touch固件
    adb install ~/下载/tp_fw/M13xxxx.apk
    am start com.eeti.android.egalaxupdateauto/.eGalaxUpdateAuto
=============//

016:uboot prinetenv/cmdline参数传递的逻辑

    bootable/bootloader/uboot-imx/include/configs/mx6f0307handroid_common.h 
    'CONFIG_EXTRA_ENV_SETTINGS'
    + 
    bootable/bootloader/uboot-imx/include/configs/mx6f0307h_common.h 
    'CONFIG_BAUDRATE'
    'CONFIG_BOOTDELAY'
    'CONFIG_LOADADDR'
    
    参数分两部份，一部分是常规的参数，还有一个是extra_env给特殊用。自己的可以加里面
    对上述参数的解析在
    'bootable/bootloader/uboot-imx/include/env_default.h'
    所有的参数均是通过宏定义


