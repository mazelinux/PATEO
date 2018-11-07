#########################################################################
# File Name: readme.sh
# Author: maze
# Email: mazema@pateo.com.cn
# Created Time: 2018年02月13日 星期二 10时38分37秒
#########################################################################

发现64g u盘没办法正常枚举成存储设备

#请将文件夹复制到本地使用
#请将文件夹复制到本地使用
#请将文件夹复制到本地使用
sudo ./venv/bin/sslocal -c ~/shadowsocks.json -d start 
翻墙：proxychains4 firefox
注意需要首次开启并且没有其他firefox页面

tools                      ---> 新员工入职指南：BSP组


=============================================
======---------------------------------======
=============================================
代码环境&代码完整编译                           ====================> ***

uboot编译                                       ====================> 000

kernel编译/ramdisk                              ====================> 001

system编译                                      ====================> 002

recovery编译                                    ====================> 003

ota升级包                                       ====================> 004

第一次烧录                                      ====================> 005

android启动逻辑                                 ====================> 006

apk安装指南                                     ====================> 007

分区挂载                                        ====================> 008

进入uboot设置参数界面                           ====================> 009

进入recovery界面                                ====================> 010

重要文件位置                                    ====================> 011

dts解析                                         ====================> 012

外设                                            ====================> 013

分支意义以及代码提交                            ====================> 014

查看安装的apk报名                               ====================> 015

uboot_printenv/cmdline传递                      ====================> 016


=============================================
======---------------------------------======
=============================================

***:代码环境

    仪表端代码下载参考readme_2.sh-->10.b

   :部分编译
        make_menuconfig.sh         ---> 辅助修改kernel_defconfig的脚本,放在root目录;android根目录
        '使用方法: ./make_menuconfig.sh'
        生成.config,并且copy到defconfig

        make_modules.sh            ---> 辅助编译kenrel所有模块;android根目录
        '使用方法: ./make_modules.sh'
        生成所有的kernel模块

        make_kernel_f0307h.sh      ---> 辅助编译完整kenrel[defconfig;uImage;modules;dtbs;boot.img];android根目录
        '使用方法: ./make_kernel_f0307h.sh f0307h'
        生成boot-imx6qp_adb.img;必须确保自己拥有mkboogimg ramdisk.img 以及 boot_signer三个工具和img包才能正常执行


   :代码完整编译
        make_f0307h.sh           ---> 辅助编译所有
        '使用方法: ./make_f0307h.sh all user'
        **
        生成所有我们有权限生成的包，其他无法生成的需要去jinkens下载
        [bsp组编译出的18show的system.img是有问题的]

   :ramdisk编译
        make ramdisk

        生成ramdisk.img

        '编译成功后,以下*开头为18show,6qp,2g所需烧录img'

        分区烧写的时候xxx分区与xxxb分区需要同时烧写相同的img

        source build/envsetup.sh
        lunch f0307h_6qp_XXX是无效的
=============//
    
000:uboot编译

*   u-boot-imx6qp.imx              ----> bootloader/uboot-imx/configs/mx6qpf0307h_android_defconfig
    u-boot-x37.imx                 ----> bootloader/uboot-imx/configs/mx6qf0307h_android_defconfig

    这俩defconfig差异
    diff mx6qf0307h_android_defconfig mx6qpf0307h_android_defconfig 
     1c1
     < CONFIG_SYS_EXTRA_OPTIONS="IMX_CONFIG=board/freescale/mx6f0307h/mx6q_ssi43tr16256a.cfg,MX6Q,ANDROID_SUPPORT"
     ---
     > CONFIG_SYS_EXTRA_OPTIONS="IMX_CONFIG=board/freescale/mx6f0307h/mx6qp_ssi43tr16512a.cfg,MX6QP,ANDROID_SUPPORT"
=============//

001:kernel编译

    "zImage"
    boot                           ----> kernel_imx/arch/arm/configs/imx_v7_x37_android_carplay_defconfig            
    boot-carlife                   ----> kernel_imx/arch/arm/configs/imx_v7_x37_android_carplay_defconfig            
    boot-adb.img                   ----> kernel_imx/arch/arm/configs/imx_v7_x37_android_defconfig [lunch 29]         
*   boot-imx6qp_adb.img
    boot-imx6qp_carlife.img
    boot-imx6qp.img

    boot.img与boot-carlife.img是同一个东西
=============//

002:system编译
    
    "system.img"[唯一]
    system.img烧录以后屏幕不会点亮背光
    背光亮度调节在/sys/class/misc/cis_mcu/bl_value
    echo 0~255 > /sys/class/misc/cis_mcu/bl_value
=============//

003:recovery编译
    "recovery"
    recovery.img
*   recovery-imx6qp.img
=============//

004:ota升级包

    本地:
    update-factory-1.0.0.20180116142817.rc5.4.user.f0307h_imx6qp_adb.zip

    网上:
    下载升级包[android原生/仪表盘]：
*   http://10.10.96.212:8080/view/1.Projects/view/PRJ_X37_6.0/job/PRJ_Android_X37/

    下载升级包[qg_android]：
    http://10.10.96.212:8080/view/1.Projects/view/PRJ_X37_6.0/job/PRJ_F0307H_6.0/
    下载前缀有factory，后缀有imx6qp-adb的zip包

    如果是全包:放在u盘,建立一个update文件夹，将zip包重命名为update.zip
    如果是map包:***************************, 将zip包重命名为map.zip

    [update的时候log查看:]
    [cat /tmp/recovery.log]
=============//

005:第一次烧录
    
    盒子硬件连接参看:  
    [一汽车展]X37车机配置方法总结.docx

    从ota仪表端下载整个img:[x37]
    例如:http://10.10.96.212:8080/view/1.Projects/view/PRJ_X37_6.0/job/PRJ_Android_X37/46/artifact/
    点击:打包下载全部文件
    解压zip包

    [系用有两套，一套为正常分区名，另外一套为b后缀分区。为避免uboot引导出错，我们在烧写的时候将两者全部烧录正常img]
    烧写:
        fastboot flash bootloader_nor u-boot-imx6qp.imx 
        fastboot flash recovery recovery-imx6qp.img 
        fastboot flash recoveryb recovery-imx6qp.img 
        fastboot flash boot boot-imx6qp_adb.img 
        fastboot flash bootb boot-imx6qp_adb.img 
        fastboot flash system system.img 
        fastboot flash systemb system.img 
    重启:
        fastboot reboot

    烧录完成后如果出现固定180s左右的机器重启现象,说明烧录的img是有问题的 
    烧录完成后如果出现固定180s左右的机器重启现象,说明烧录的img是有问题的 
    烧录完成后如果出现固定180s左右的机器重启现象,说明烧录的img是有问题的 
=============//

006:android启动逻辑

    --->"boot ok?"                  yes:boota mmc1
    --->"bootb ok?"                 yes:boota mmc1 bootb
    --->"recovery ok?"              yes:boota mmc1 recovery
    --->"recoveryb ok?"             yes:boota mmc1 recoveryb
    待验证×××××××××××××××××××××
=============//

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

    若adb不可用，首先应确认是否执行otg_control 1
    若adb不可用，首先应确认是否执行otg_control 1
    若adb不可用，首先应确认是否执行otg_control 1
=============//

009:进入uboot参数配置界面/初始化参数
    
    reboot重启过程中,按住shift + > .
    [printenv查看一下bootcmd是否正确]

    初始化参数：
        bpram clear
        [有些时候boot啥的烧的有问题了以后，不停的进入recovery。可以确认boot正常的情况下使用这条命令重置启动参数]

=============//

010:进入recovery界面

    在正常的kernel界面输入:
        minirecovery 30
    或者
        reboot recovery
    [如果你两个boot分区都错误,那么下次也会进入recovery]
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

    "module"
    仪表端触摸屏       ----> kernel_imx/drivers/input/touchscreen/egalax_i2c.c

    "Makefile"
    make后缀           ----> build/core/Makefile
    make all;make allpackage;make bootimage;*****

    "lcd背光亮度"
                       ----> /sys/class/misc/cis_mcu/bl_value
    自己编译的system.img是为0

    "CPU温度"
                       ----> /sys/devices/virtual/thermal/thermal_zone0/temp
    实际温度是这个值除以1000
    [当这个值达到59325时，仪表盘app开始跳动]

    "散热风扇"         ----> kernel_imx/drivers/cis/f0307h/cis_mcu.c            ----> cis_mcu_recv_data 
    [待验证]当主板温度到达60度时，触发散热，当主板温度低于50度时，关闭散热
=============//

012:dts解析

    PIN:
    a.kernel_imx/arch/arm/boot/dts/imx6q-pinfunc.h             ----> 定义宏[所有的引脚复用]
    b.kernel_imx/arch/arm/boot/dts/imx6qdl-f0307h.dtsi         ----> 设置宏[对应的功能加入不同的模块]
    c.drivers/pinctrl/freescale/pinctrl-imx.c                  ----> imx_pinctrl_parse_groups[解析宏]
    
    整个解释在https://blog.csdn.net/michaelcao1980/article/details/50730421
    例如:
    在imx6q-pinfunc.h里面有：
    a     #define MX6QDL_PAD_NANDF_CS2__GPIO6_IO15            0x2ec 0x6d4 0x000 0x5 0x0

    在imx6qdl-f0307h.dtsi里面写成：
    b             MX6QDL_PAD_NANDF_CS2__GPIO6_IO15 0x80000000 /* WIFI EN */                  0x2ec 0x6d4 0x000 0x5 0x0 0x80000000

    在pinctrl-imx.c里面按照如下解析：
    c             MX6QDL_PAD_引脚名称 __引脚功能描述[用来做啥，gpio,pwm还是其他啥]           mux_ctrl_ofs  |  pad_ctrl_ofs |  sel_input_ofs |  mux_mode             | sel_input   |  pad_ctrl
                                                                                             mux地址       |  pad地址      |  sel_input地址 |mux值tx,rx,pwm,gpio... | sel值       |寄存器配置（上拉电阻、频率等）

    a 理解
    b pad_ctrl要设置对！[0x80000000就是普通的gpio，其他则不一样]
    c 不必管

    example:git show c5a3bd92865ba22648f9b2f51e5377e41078973f

    INTERRUPT:
    MX6QDL_PAD_NANDF_CS2__GPIO6_IO16 代表第6组gpio中的第16个gpio口，其中每组gpio有32个*
    arch/arm/mach-imx/hardware.h                             ----> IMX_GPIO_NR
    在驱动中使用gpio_request时，io端口号为IMX_GPIO_NR(6,16)=32*(6-1)+16=176

    [所有关于dts的文档在Documentation/devicetree/bindings/*fsl*]




   基于 linux gpio 会在 /sys/class/gpio 目录下会生成 export, unexport 文件.
   当然也有 gpiochipx 文件，gpiochipx 是对引脚的管理，如某一个 chip 可能控制着一定数量的引脚，在相应目录下 ngpio 是控制的数量。
   执行 echo 4 > /sys/class/gpio/export 的时候会在 /sys/class/gpio 目录下生成 gpio4 目录，
   在这个目录下会有如 value, edge, direction 等相关文件，value 是当前值， edge 是引脚触发方式，direction 是引脚输入，输出方式。但是 echo 之后如何产生这个的呢。

   在一开始的初始化过程中有函数 gpiolib_dev_init 被导出为 core_initcall (gpio/gpiolib.c)
   此函数调用 bus_register 注册 gpio ，对应生成 /sys/bus/gpio 目录
   再调用 alloc_chrdev_region
   再进行gpiochip 的设置 gpiochip_setup_devs
   这会对总数量 的 gpiochip 进行处理，对每个调用 gpiochip_sysfs_register，文件到了 gpiolib-sysfs.c 中
   调用 device_create_wtih_groups来创建 gpiochip%d
   此函数对应的参数为 gpio_class 即一个 class 类
   此 class 定义的名称是 gpio, 同时定义了 attr
   attr 包括 export - export _store, unexport - unexport_store
   前者是属性名，后者是函数
   也就是 echo 动作为触发 export_store 函数
   此函数 调用 gpio_request 准备引脚
   再调用 gpiod_export 在此函数中调用 device_create_with_groups 来创建 gpio%d，以及其它事项
=============//

013:外设

前仓
    lvds显示屏[1920*720]主机 12.3
    lvds显示屏[1920*720]仪表
    lcd*1 ldb*1

    kernel/drivers/video/fbdev/mxc/ldb.c

    kernel/drivers/video/fbdev/mxc/mxc_lcdif.c
    LCD驱动程序中的pixclock的计算方法:
        dotclock = (x向分辨率+左空边+右空边+HSYNC长度)* (y向分辨率+上空边+下空边+YSYNC长度)*整屏的刷新率[一秒钟多少张图片]
        DOTclock = fframe × (X + HBP + HFP+HSPW) × (Y + VBP + VFP+VSPW)  (单位：MHz)
        PIXclock = 1012/DOTCLK  = 1012/（fframe × (X + HBP + HFP+HSPW) × (Y + VBP + VFP+VSPW)） (单位：皮秒)
        pixclock = 1/dotclock  其中dotclock是视频硬件在显示器上绘制像素的速率

    "mipi"

     H-total = HorizontalActive + HorizontalFrontPorch + HorizontalBackPorch + HorizontalSyncPulse + HorizontalSyncSkew
     V-total = VerticalActive + VerticalFrontPorch + VerticalBackPorch + VerticalSyncPulse + VerticalSyncSkew
     Total pixel = H-total x V-total x 60 (Hz)
     Bitclk = Total pixel x bpp (byte) x 8/lane number
     Byteclk = bitclk/8
     Dsiclk = Byteclk x lane number
     Dsipclk = dsiclk/bpp (byte)

    1、DSI vdo mode下的数据速率data_rate的大致计算公式为：
    Data rate= (Height+VSA+VBP+VFP)*(Width+HSA+HBP+HFP)* total_bit_per_pixel*frame_per_second/total_lane_num
                                                         888:24 666:18       一秒钟多少帧     几路数据
     

    2、DSI cmd mode下的数据速率data_rate的大致计算公式为：
    Data rate= width*height*1.2* total_bit_per_pixel*frame_per_second/total_lane_num

    参数注释：
    data_rate ： 表示的是数据速率
    width，height  ：屏幕分辨率
    VSA VBP VFP ：DSI vdo mode的vertical porch配置参数
    HSA HBP HFP ：DSI vdo mode的horizontal porch配置参数
    total_bit_per_pixel ：表示的是一个pixel需要用几个bit来表示，比如RGB565的话就是16个bit
    frame_per_second ：就是我们通常看到的fps，叫做帧率，表示每秒发送多少个帧，一般是60帧每秒
    total_lane_num ：表示的是data lane的对数。



    gps模块

    收音天线

    otg，usbhost，tbox线usb

    麦克风

    audio

    led氛围灯

    触摸屏*2

    uart串口模块
    kernel/drivers/tty/serial/imx.c
    kernel/drivers/tty/serial/fsl_lpuart.c

    spi_nor_mtd
    kernel/drivers/mtd/devices/m25p80.c

后仓
    1080*720 15.6

    前仓和后仓img其实差不都。bsp这边的话。uboot里面的cmdline如果正确的话。其实是可以做到12.3;10.5;15.6之间屏幕切换的。但是触摸并不可以。
=============//

014:代码提交&分支信息

    jupiter 是车展仪表盘;裸android代码[12.3]
    branch jupiter_android
    jenkins http://10.10.96.212:8080/view/1.Projects/view/PRJ_X37_6.0/job/PRJ_Android_X37/
    新版对应branch jupiter_18show_dashboard 
    jenkins http://10.10.96.212:8080/view/1.Projects/view/PRJ_18Show_dashboard/job/PRJ_18Show_dashboard/


    18show  是车展主机端[12.3]
    branch jupiter_x37_18show
    jenkins http://10.10.96.212:8080/view/1.Projects/view/PRJ_18Show_6.0/job/PRJ_18Show_6.0/
    新版对应branch jupiter_18show_fzk
    jenkins http://10.10.96.212:8080/view/1.Projects/view/PRJ_18Show_fzk/job/PRJ_18Show_fzk/


    f0307h  是x37代码[10.5]
    branch jupiter_f0307h
    jenkins http://10.10.96.212:8080/view/1.Projects/view/PRJ_X37_6.0/job/PRJ_F0307H_6.0/


    jupiter_18show_bzk 是后排两块屏的android[15.6]
    branch jupiter_18show_bzk
    jenkins http://10.10.96.212:8080/view/1.Projects/view/PRJ_18Show_bzk/job/PRJ_18Show_bzk/

    ANDROID_VERSION=6.0.1
    KERNEL_VERSION=4.1.15

    git push origin HEAD:refs/for/xxxxxxxxxxxx
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


