#########################################################################
# File Name: imx8_readme.sh
# Author: maze
# Email: mazema@pateo.com.cn
# Created Time: 2018年05月21日 星期一 10时01分20秒
#########################################################################
#!/bin/bash

am start com.android.settings/.Settings
=============================================
======---------------------------------======
=============================================

CIS协议                                        ====================> 0000
DDR初始化                                      ====================> 0001
BLUETOOTH                                      ====================> 0002
SELINUX协议                                    ====================> 0003
MAKE_IMAGE                                     ====================> 0004
DISPLAY_4PANNEL                                ====================> 0005
FSTAB_文件系统                                 ====================> 0006
ADB_FASTBOOT工具                               ====================> 0007
Android-O:init                                 ====================> 0008
Android网关协议                                ====================> 0009
Imx8qm平台下spi_norflash启动                   ====================> 0010
增加fastboot下关于bootloader_nor分区以及刷写   ====================> 0011
Imx8qm Uboot build reference                   ====================> 0012

=============================================
======---------------------------------======
=============================================


##########################################################################################################################
0000                                                    CIS
##########################################################################################################################
'问mcu组要:
    pcan工具
    sip协议 xlsx'

1..硬件上的逻辑是怎么样的。
2..软件上的逻辑是怎么样的。
驱动主要处理mpu与mcu之间的交互
从下至上有:经过mcu处理的消息，以及原生的can传上来的数据
从上至下有:mpu向下发送控制命令;走的是uart;外加一个reset引脚

    'MPU'<----------uart4----------->'MCU'<------------can---------->'DEV'
     CIS-------------CIS------------[通信协议&数据逻辑]

cis-->debug
        /sys/module/cis_mcu_parameters/debug

    code drivers/cis/*                      [基本是common的]
         drivers/cis/product/*              [cis_mcu,上层接口是--->can bus service]
         dirvers/cis/product/vinson/*       [cis_can_##product##,上层接口是--->car signal service]

##########################################################################################################################
##########################################################################################################################
'CIS_MCU.C':                                
                                            [xlsx里面其他]

                                            [app-id == aid][rep-id/req-id == fid][rep与req是不同的类型一个是report，一个是request]
            cis_mcu_recv_item;              [id,    len, app-id, 'index',   rep-id, flag, name]
            cis_mcu_cmd_item;               ['id',  len, app-id,  req-id,   rep-id, flag, name]
                                            #id与index是一个东西#

'    获取/设置数据:
        cis_mcu_get_data;                   [aid, fid, *pdata, len]
        cis_mcu_set_data;                   [aid, fid, *pdata, len]
'
    逻辑
        cis_mcu_show_property               ---->cis_mcu_get_data
        cis_mcu_store_property              ---->cis_mcu_set_data/cis_mcu_recv_data/gpio_set_value
                                            ---->---->cis_mcu_recv_data
                                            ---->---->---->cis_mcu_recv_handler
                                            ---->---->---->g_cis_mcu_cb = sigdet_update_mcu_message

    debug
            /sys/module/cis_mcu/parameters/debug

1.增加一个外设:逻辑写法
    cis_mcu.c                               ---->struct cis_mcu_recv_item cis_mcu_recv_cmds[x]                  ::增加新的cis_mcu_recv_entry;
                                            ---->struct cis_mcu_cmd_item  cis_mcu_cmds[x]                       ::增加新的cis_mcu_command_entry;两者之间的关系'#id与index是相连的#'
                                            ---->enum cis_mcu_property                                          ::增加新的case
                                            ---->static ssize_t cis_mcu_[show/store]_property                   ::对新加的case添加处理逻辑
                                            ---->static struct device_attribute cis_mcu_dev_attrs[]             ::增加新的sys/device/virtual/mics/cis_mcu/*节点
                                            ---->static struct attribute *cis_mcu_attrs                         ::增加新的sys/device/virtual/mics/cis_mcu/*节点

##########################################################################################################################
##########################################################################################################################
'CIS_CAN_##PRODUCT##.C':                    
                                            [xlsx里面Vehicle&Can]

    函数：
        int cis_can_register_protocol(unsigned char* protocol,     fun_cis_can_recv_spec_handle can_recv,         fun_cis_can_send_spec_handle can_send,             fun_cis_canbox_ack_send can_ack, struct cis_can_capacity * can_cap)
    赋值：
        cis_can_register_protocol("can_e0001h",cis_can_e0001h_recv_handle,cis_can_e0001h_send_handle,NULL,&cis_can_e0001h_cap);
    则：
        cis_can_recv_spec_handle = can_recv;[cis_can_e0001h_recv_handle]
        cis_can_send_spec_handle = can_send;[cis_can_e0001h_send_handle]
        cis_canbox_ack_send      = can_ack; [NULL]
        cis_can_cap              = can_cap; [cis_can_e0001h_cap]




###
            cis_can_recv_item;              [cis_can_e0001h_recv_cmds]
                                            [proto_id == msg_frame->type][canbox_subid == aid][canbox_id == fid]
                cis_can_recv_entry          [proto_id,  proto_data_len,     canbox_id,  canbox_subid,       canbox_data_len, can_item_parser, flag, name]

'    获取数据:
        cis_can_e0001h_recv_handle  ---->cis_can_e0001h_recv_cmds 
                                           ---->cis_can_e0001h_recv_cmds[i].can_item_parser[对数据进行处理]
                                           ---->cis_can_cb(packet_fmt)[将数据发往userspace] 
                                           ---->report_uevent(packet_fmt)[将数据发往userspace]
'
###


###
            cis_can_send_item;              [cis_can_e0001h_send_cmds]
                cis_can_send_entry          [sproto_id, sproto_data_len,    scanbox_id, scanbox_data_len,   can_item_convert]

'    设置数据:
        cis_can_e0001h_send_handle  ---->cis_can_e0001h_send_cmds
                                            ---->cis_can_e0001h_send_cmds[i].can_item_convert(xxx)[对数据进行处理,并且通过memcpy写入相应的地方]
'
###

            raw_data[for raw data frame]    ---->raw_frame
            raw 数据通过handle 赋值给msg_data
            msg_data[for uevent]            ---->msg_frame

            在handle里面对数据处理msg_data[##xx##] = raw_data[##yy##]xxxxxx [这个转换过程逻辑应该有专门的spec文档]
            msg_data是传给上层，raw_data是底层can消息需要转换成正确消息msg_data传给上层

            cis_can_frame;
            cis_can_e0001h_frame;

    debug
            /sys/module/cis_can_vinson/parameters/debug


1.增加一个外设:逻辑写法
    cis_can_core.h                          ---->enum REQUEST_CONTROL_COMMAND                                   ::增加新的case
    cis_can_##product##.c                   ---->static void ##product##_parse_xxx_info                         ::增加新的接收数据处理函数
                                            ---->struct cis_can_recv_item cis_can_##product##_recv_cmds[x]      ::增加新的接收命令格式，cis_can_recv_entry[xx.xx[处理函数]xx.xx]
                                            ---->static cis_can_send_item cis_can_##product##_send_cmds[x]      ::增加新的发送命令格式，cis_can_send_entry[xx.xx[处理函数]xx.xx]

##########################################################################################################################
##########################################################################################################################
'目前dts里面没有描述以下设备'
alarm_sound.c                               [报警声音]这个应该是从mpu向下写命令的逻辑
                                            首先，这个文件应该是不需要动的
    逻辑
            probe                       ---->cis_can_register_cb2(alarm_update_can_message)                     ::cis_can_register_cb2在cis_can_core.c里面
                                        ---->---->g_cis_can_cb2 = alarm_update_can_message
                                        ---->---->cis_can_report_uevent   ---->cis_uio_send_msg()     ---->netlink_broadcast
                                        ---->---->---->cis_can_recv_spec_handle(data,cis_can_report_uevent,g_cis_can_cb2)
                                        [这其中，cis_can_report_uevent与g_cis_can_cb2上报的最终函数均是netlink_broadcast,但是两者的flag是不一样的！！！]

            alarm_update_can_message    ---->cis_uio_send_msg()                             ---->netlink_broadcast[将数据发送到userspace][case cis_uio_socket_alarm]

            alarm_store_property        ---->写入0-8,总计九个节点。
            alarm_show_property         ---->查看0-9,总结十个节点。

    debug
            /sys/module/alarm_sound/parameters/debug

sigdet.c                                    [倒车影像]
    逻辑
            probe                       ---->cis_can_register_cb(sigdet_update_can_message)                     ::cis_can_register_cb在cis_can_core.c里面
                                        ---->---->g_cis_can_cb = sigdet_update_can_message
                                        ---->---->cis_can_report_uevent   ---->cis_uio_send_msg()     ---->netlink_broadcast
                                        ---->---->---->cis_can_recv_spec_handle(data,cis_can_report_uevent,g_cis_can_cb)

                                        ---->cis_mcu_register_cb(sigdet_update_mcu_message) ---->cis_mcu_register_cd在cis_mcu.c里面
                                        ---->---->g_cis_mcu_cb = sigdet_update_mcu_message
            sigdet_update_can_message   ---->cis_uio_send_msg()                             ---->netlink_broadcast[将数据发送到userspace]
            sigdet_update_mcu_message   ---->cis_uio_send_msg()                             ---->netlink_broadcast[将数据发送到userspace]

    debug
            /sys/module/sigdet/parameters/debug


    cis_core.h
    cis_packet_format[发送/接受数据包]



##########################################################################################################################
0001                                                    DDR
##########################################################################################################################
'U-BOOT vendor部分代码编译':

            src :/home/maze/下载/imx8/memory/uboot额外代码/vendor-uboot/packages/imx-scfw-porting-kit-0.4/src/
            步骤:['替换mx8qm-scfw-tcm.bin重新生成正常的uboot']
                1-1.export TOOLS=/home/maze/下载/imx8/
                1-2.cd /home/maze/下载/imx8/memory/uboot额外代码/vendor-uboot/packages/imx-scfw-porting-kit-0.4/src/scfw_export_mx8qm
                1-3.make -e qm B=mek
                1-4.cp /home/maze/下载/imx8/memory/uboot额外代码/vendor-uboot/packages/imx-scfw-porting-kit-0.4/src/scfw_export_mx8qm/build_mx8qm/scfw_tcm.bin 'android'/vendor/nxp/fsl-proprietary/uboot-firmware/imx8q/mx8qm-scfw-tcm.bin
                1-5.rm 'android'/out/target/product/vinson/u-boot-imx8qm.imx
                1-6.source build/envsetup.sh
                1-7.lunch xxxx
                1-8.make bootloader

'U-BOOT 部分关于ddr的src':

            a.vendor/nxp-opensource/uboot-imx/common/board_f.c                                                          [定义整个uboot阶段初始化板子的逻辑:init_fnc_t init_sequence_f] 
            b.                               /include/configs/imx8qm_vinson.h                                           [定义ddr大小以及起始位置,bank数量,还有很多其他的定义]
            c.                               /arch/arm/cpu/armv8/imx8/cpu.c                                             [特殊的启动函数在board_f.c里面没有实现，在这个文件实现]
            注意:__weak 函数前缀的使用方法
##########################################################################################################################
##########################################################################################################################

'U-BOOT 修改ddr的方法':                                               
                    
            src :/home/maze/下载/imx8/memory/uboot额外代码/vendor-uboot/packages/imx-scfw-porting-kit-0.4/src/
                '#':/home/maze/下载/imx8/memory/MX8QXP_LPDDR4_register_programming_aid_ValidationBoard_1.2GHz_v10_DBI_enabled.xlsx
            步骤:['比如硬件上4g+4g lpddr4']
                1.修改'#.xlsx'里面的Register Configuration里面的Device Information[按实际硬件配置]
                2.将'#.xlsx'里面生成的DCD CFG file拷贝到/home/maze/下载/imx8/memory/uboot额外代码/vendor-uboot/packages/imx-scfw-porting-kit-0.4/src/scfw_export_mx8qm/platform/board/mx8qm_mek/dcd/imx8qm_dcd_1.6GHz.cfg
                3.执行1-1 到 1-4所有步骤
                4.修改b中的PHYS_SDRAM_2_SIZE 为6g
                5.执行1-5 到 1-8
                6.烧写uboot
            注意：#.xlsx里面还有测试ddr稳定性，对.cfg进行微调的工具，目前没有实践过，不知道咋用

https://www.techbang.com/posts/18381-from-the-channel-to-address-computer-main-memory-structures-to-understand


'DDR 压力测试工具nxp': windows+工具
            1.工具安装
            2.跳线让设备枚举成hdi设备
            3.运行压力测试工具，接好串口

##########################################################################################################################
0002                                                    BLUETOOTH
##########################################################################################################################

https://blog.csdn.net/u010164190/article/details/51907839
https://source.android.com/devices/bluetooth/
            蓝牙低功耗 (BLE)                在 Android 4.3 及更高版本中，Android 蓝牙堆栈可提供实现蓝牙低功耗 (BLE) 的功能。
'APK':                            
            [Service + JNI]
            packages/apps/Bluetooth                             [apk +service ]
            packages/apps/Bluetooth/jni                         [jni]

'LIB':
            [HAL + STACK]
            hardware/libhardware/include/hardware/bluetooth.h
            hardware/interface/bluetooth                        [hal]
            system/bt/*                                         [stack]

'KERNEL':  [串口{蓝牙与soc通信} + 几个pin脚] 
            kernel/driver/bluetooth/mx8_bt_rfkill.c
            kernel/driver/tty/serial/fsl_lpuart.c
            
##########################################################################################################################
##########################################################################################################################
'蓝牙4.0'     :低功耗蓝牙，传统蓝牙，高速蓝牙   
              (BLE) Bluetooth Low Energy 也叫 Bluetooth Smart
'蓝牙上层协议':
            GAP和GATT则主要用于蓝牙设备的可被发现以及扫描工作。
            通用访问规范（GAP）
            'GAP'代表通用访问配置文件，它控制连接和被发现的过程。GAP能够确保您的设备对所有人都可见。一旦建立了外围设备和中央设备之间的连接，蓝牙设备通常也将停止被发现，您通常将无法再发送被发现过程的数据包，这时您就需要使用GATT的服务和特性在两个方向进行通信。
            通用属性规范（GATT）
            'GATT'代表通用属性配置文件，它定义了客户端和服务器之间的通信语义。当连接建立时，它起着一个作用，这一作用使用了一个概念，称为简档，服务和特征。该配置文件是使用Bluetooth SIG或外围设计器编译的预定义服务集合。服务可能包含一个或多个特性，它用于分解不同实体中的数据，并以16位或128位UUID标识。特性封装单个数据点，并在16位或128位UUID中标识。
            逻辑链路控制和适配协议（L2CAP）
            属性协议（AttributeProtocol）
            安全管理协议（SecurityManagerProtocol）

https://blog.csdn.net/qq_29923439/article/details/74980842
蓝牙技术联盟网站:www.bluetooth.org 
开发者网站:developer.bluetooth.org
蓝牙博客:blog.bluetooth.com
##########################################################################################################################
##########################################################################################################################
'android'/vendor/nxp-opensource/kernel_imx/arch/arm64/boot/dts/freescale/fsl-imx8qm-vinson.dts
硬件上是接的uart与soc通信 uart1+enable脚
dts里面有rx，tx，cts，rts，enable_gpio，外加俩主机/设备互相唤醒脚

&lpuart1 { /* BT */
	pinctrl-names = "default";
	pinctrl-0 = <&pinctrl_lpuart1 &pinctrl_bt>;
	status = "okay";
};
	pinctrl_lpuart1: lpuart1grp {
		fsl,pins = <
			SC_P_UART1_RX_DMA_UART1_RX		0x0600002c
			SC_P_UART1_TX_DMA_UART1_TX		0x0600002c
			SC_P_UART1_CTS_B_DMA_UART1_CTS_B	0x0600002c
			SC_P_UART1_RTS_B_DMA_UART1_RTS_B	0x0600002c
		>;
	};

	pinctrl_bt: btgrp {
		fsl,pins = <
			SC_P_ADC_IN0_LSIO_GPIO3_IO18		0x00000021	/* IVT BT_EN */
			SC_P_ADC_IN2_LSIO_GPIO3_IO20		0x00000021	/* IVT BT_WAKE_HOST INT*/
			SC_P_SPI2_SDI_LSIO_GPIO3_IO09		0x00000021	/* IVT HOST_WAKE_BT INT*/
		>;
	};



##########################################################################################################################
0003                                                    SELINUX  
##########################################################################################################################
'修改测略'：
            log:01-01 00:00:20.828  3665  3665 W sh      : type=1400 audit(0.0:12): avc: denied { write } for name="core_pattern" dev="proc" ino=11742 scontext=u:r:brlinkd:s0 tcontext=u:object_r:usermodehelper:s0 tclass=file permissive=0
            分析: scontext=u:r:brlinkd
                  tcontext=u:object_r:usermodehelper
                  tclass=file
                  avc:denied{write}
            解析:在brlinkd.te里面写
            allow brlinkd usermodehelper:file write;

            src:
                    device/xxfslxx/xxvinsonxx/sepolicy
                    system/sepolicy 
            define:
                    system/sepolicy/*/global_macros

'关闭selinux策略'：
            在system/core/init/init.rc里面

                static selinux_enforcing_status selinux_status_from_cmdline() {
                    selinux_enforcing_status status = SELINUX_ENFORCING;
             
                    import_kernel_cmdline(false, [&](const std::string& key, const std::string& value, bool in_qemu) {
                        if (key == "androidboot.selinux" && value == "permissive") {
                            status = SELINUX_PERMISSIVE;
                        }
                    });
            
                    return status;
                }
            如上判断kernel_cmdline里面是否有androidboot.seliux;enforcing为打开,permissive为关上。
            
            所以在Boardconfig.mk里面对BOARD_KERNEL_CMDLINE进行添加androidboot.selinux=permissive即可关闭selinux


##########################################################################################################################
0004                                                    MAKE_IMAGE
##########################################################################################################################

'MAKE_IMAGE':

            src :rootdir/build/core/*.mk
                 rootdir/build/core/Makefile                        [里面很多变量是在device/fsl/vinson/BoardConfig.mk里面定义的]

            target :ramdisk
                    bptimage
                    vendorimage
                    vbmetaimage
                    systemimage
                    ****等等[具体的target可以查看main.mk里面的 .PHONY :droidcore，这个target包含所有的编译目标]





##########################################################################################################################
0005                                                    DISPLAY_4PANNEL
##########################################################################################################################
'MIPI_INTERFACEi':
                    MIPI（Mobile Industry Processor Interface）是2003年由ARM， Nokia， ST ，TI等公司成立的一个联盟，目的是把手机内部的接口如摄像头、显示屏接口、射频/基带接口等标准化，从而减少手机设计的复杂程度和增加设计灵活性。
                    MIPI联盟下面有不同的WorkGroup，分别定义了一系列的手机内部接口标准，比如摄像头接口CSI、显示接口DSI、射频接口DigRF、麦克风/喇叭接口SLIMbus等。

            http://www.elecfans.com/yuanqijian/jiekou/20171113578403.html

'硬件上四块屏幕：两块lvds，两块mipi-dsi':    

                framework改动:
                1.deivce/fsl/imx8/vinson.mk
                           PRODUCT_COPY_FILES += \
                                   frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
                                   frameworks/native/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \
                                   frameworks/native/data/etc/android.software.sip.voip.xml:system/etc/permissions/android.software.sip.voip.xml \
                 ++++++++++        frameworks/native/data/etc/android.software.activities_on_secondary_displays.xml:system/etc/permissions/android.software.activities_on_secondary_displays.xml \
                                   frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
                                   frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
                                   frameworks/native/data/etc/android.hardware.camera.xml:system/etc/permissions/android.hardware.camera.xml \


                2.framework/native/services/inputflinger/EventHub.cpp
                 bool EventHub::isExternalDeviceLocked(Device* device) {
                 +
                 +       // add by jingmingyan for dual display touch
                 +    if (device->path.contains("/dev/input/event3")) {
                 +        return 0;
                 +    }
                 +    if (device->path.contains("/dev/input/event7")) {
                 +        return 1;
                 +    }
                 +    // add by jingmingyan end
                 +
                      if (device->configuration) {
                               bool value;
                                        if (device->configuration->tryGetProperty(String8("device.internal"), value)) {




##########################################################################################################################
0006                                                    FSTAB_文件详解     
##########################################################################################################################
'fsl的fstab存放在':
            device/fsl/xxxx/fstab.freescale
            # Android fstab file.
            #<src>      <mnt_point>         <type>    <mnt_flags and options>                       <fs_mgr_flags>
            /dev/block/by-name/userdata    /data        ext4    nosuid,nodev,nodiratime,noatime,nomblk_io_submit,noauto_da_alloc,errors=panic    wait,formattable,encryptable=/dev/block/by-name/datafooter,quota

            <type> - 要挂载设备或是分区的文件系统类型，支持许多种不同的文件系统：ext2, ext3, ext4, reiserfs, xfs, jfs, smbfs, iso9660, vfat, ntfs, swap 及 auto。 设置成auto类型，mount 命令会猜测使用的文件系统类型，对 CDROM 和 DVD 等移动设备是非常有用的。
            <options> - 挂载时使用的参数，注意有些mount 参数是特定文件系统才有的。一些比较常用的参数有：

                    auto - 在启动时或键入了 mount -a 命令时自动挂载。
                    noauto - 只在你的命令下被挂载。
                    exec - 允许执行此分区的二进制文件。
                    noexec - 不允许执行此文件系统上的二进制文件。
                    ro - 以只读模式挂载文件系统。
                    rw - 以读写模式挂载文件系统。
                    user - 允许任意用户挂载此文件系统，若无显示定义，隐含启用 noexec, nosuid, nodev 参数。
                    users - 允许所有 users 组中的用户挂载文件系统.
                    nouser - 只能被 root 挂载。
                    owner - 允许设备所有者挂载.
                    sync - I/O 同步进行。
                    async - I/O 异步进行。
                    dev - 解析文件系统上的块特殊设备。
                    nodev - 不解析文件系统上的块特殊设备。
                    suid - 允许 suid 操作和设定 sgid 位。这一参数通常用于一些特殊任务，使一般用户运行程序时临时提升权限。
                    nosuid - 禁止 suid 操作和设定 sgid 位。
                    noatime - 不更新文件系统上 inode 访问记录，可以提升性能(参见 atime 参数)。
                    nodiratime - 不更新文件系统上的目录 inode 访问记录，可以提升性能(参见 atime 参数)。
                    relatime - 实时更新 inode access 记录。只有在记录中的访问时间早于当前访问才会被更新。（与 noatime 相似，但不会打断如 mutt 或其它程序探测文件在上次访问后是否被修改的进程。），可以提升性能(参见 atime 参数)。
                    flush - vfat 的选项，更频繁的刷新数据，复制对话框或进度条在全部数据都写入后才消失。
                    defaults - 使用文件系统的默认挂载参数，例如 ext4 的默认参数为:rw, suid, dev, exec, auto, nouser, async.
            https://blog.csdn.net/richerg85/article/details/17917129

'ext挂载问题':                    
            同ntfs一样，android默认的是不支持ext*格式的,可以自己把这些格式的支持加上去，但有一个问题，ext*不像fat那样挂载的时候支持uid、gid、fdmask等 参数，
            这会导致文件系统挂载上去后，发现还有一个问题，ext2,ext3,ext4的挂载上去后在应用中文件看不到，查了下原因是因为应用不能写u盘，说的具体点是应用的这个用户没有权限写u盘
            https://blog.csdn.net/new_abc/article/details/7459299

'切换分区读写模式'：
          mount -o rw,remount -t ext4 /dev/block/mmcblk0p5 /system

##########################################################################################################################
0007                                                    ADB_FASTBOOT工具 
##########################################################################################################################
'/system/core/下面有很多的工具，其中包括adb，fastboot，logcat，toolbox等等'

'ADB源码位置':
            /system/core/adb
            adb的工作是由adb，adbd两个可执行文件完成的。
            在remount_service.cpp里面，有个逻辑:
                if (android::base::GetBoolProperty("ro.build.system_root_image", false)) {
                         success &= remount_partition(fd, "/");
                } else {
                         success &= remount_partition(fd, "/system");
                }
                success &= remount_partition(fd, "/vendor");
                success &= remount_partition(fd, "/oem");
            可见，如果存在ro.build.system_root_image为true，则remount /;否则remount /system
            再看remount_partition:
                                make_block_device_writable(dev); -->ioctl(fd,BLKROSET,&OFF);将块设备置为读写
                                mount
            所以实际上两件事，先把block设备置为可读写，然后重新mount分区
            
https://blog.csdn.net/vichie2008/article/details/40823531

'FASTBOOT源码位置':
            /system/core/fastboot

##########################################################################################################################
0008                                                    Android-O:init
##########################################################################################################################
'AndroidO与之前版本差异'：
            以前版本的Android:
                        系统Native服务，不管它们的可执行文件位于位置都定义在根分区的init.*.rc文件中。
            Android O        :
                        单一的init＊.rc被拆分，服务根据其二进制文件的位置（/system，/vendor，/odm）定义到对应分区的etc/init目录中，每个服务一个rc文件.与该服务相关的触发器、操作等也定义在同一rc文件中。 
                        /system/etc/init，包含系统核心服务的定义，如SurfaceFlinger、MediaServer、Logcatd等。
                        /vendor/etc/init， SOC厂商针对SOC核心功能定义的一些服务。比如高通、MTK某一款SOC的相关的服务。
                        /odm/etc/init，OEM/ODM厂商如小米、华为、OPP其产品所使用的外设以及差异化功能相关的服务。

##########################################################################################################################
0009                                                    Android网关协议   
##########################################################################################################################
'ip命令':
        ip rule list                                    [显示所有的路由表，并且从上往下按优先级高到低排序]

        0:  from all lookup local 
        10000:  from all fwmark 0xc0000/0xd0000 lookup legacy_system 
        13000:  from all fwmark 0x10063/0x1ffff lookup local_network 
        15000:  from all fwmark 0x0/0x10000 lookup legacy_system 
        16000:  from all fwmark 0x0/0x10000 lookup legacy_network 
        17000:  from all fwmark 0x0/0x10000 lookup local_network 
        23000:  from all fwmark 0x0/0xffff uidrange 0-0 lookup main 
        32000:  from all unreachable

'linux可以自定义从1－252个路由表''linux系统维护了4个路由表'：
        0#表 系统保留表
        253#表 defulte table 没特别指定的默认路由都放在改表
        254#表 main table 没指明路由表的所有路由放在该表
        255#表 locale table 保存本地接口地址，广播地址、NAT地址 由系统维护，用户不得更改

'路由表的查看可有以下二种方法'：
        ip route list table table_number
        ip route list table table_name

'路由表序号和表名的对应关系在/data/misc/rt_tables中，可手动编辑':
        ip route add default via 192.168.1.1 table 1 在一号表中添加默认路由为192.168.1.1
        ip route add 192.168.0.0/24 via 192.168.1.2 table 1 在一号表中添加一条到192.168.0.0网段的路由为192.168.1.2
        注:各路由表中应当指明默认路由,尽量不回查路由表.路由添加完毕,即可在路由规则中应用..

'路由规则的添加':
        进行路由时，根据路由规则来进行匹配，按优先级（pref）从低到高匹配,直到找到合适的规则.所以在应用中配置默认路由是必要的..     
        ip rule show 显示路由规则
        路由规则的添加
        ip rule add from 192.168.1.10/32 table 1 pref 100
        如果pref值不指定，则将在已有规则最小序号前插入
        注：创建完路由规则若需立即生效须执行#ip route flush cache;刷新路由缓冲
            可参数解析如下:
                From -- 源地址
                To -- 目的地址（这里是选择规则时使用，查找路由表时也使用）
                Tos -- IP包头的TOS（type of sevice）域Linux高级路由-
                Dev -- 物理接口
                Fwmark -- iptables标签
                采取的动作除了指定路由表外，还可以指定下面的动作：
                Table 指明所使用的表
                Nat 透明网关
                Prohibit 丢弃该包，并发送 COMM.ADM.PROHIITED的ICMP信息 
                Reject 单纯丢弃该包
                Unreachable丢弃该包， 并发送 NET UNREACHABLE的ICMP信息
                具体格式如下：更强大，使用更灵活，它使网络管理员不仅能
                Usage: ip rule [ list | add | del ] SELECTOR ACTION
                SELECTOR := [ from PREFIX ] [ to PREFIX ] [ tos TOS ][ dev STRING ] [ pref NUMBER ]
                ACTION := [ table TABLE_ID ] [ nat ADDRESS ][ prohibit | reject | unreachable ]
                          [ flowid CLASSID ]
                TABLE_ID := [ local | main | default | new | NUMBER ]

https://my.oschina.net/u/1397402/blog/736806
https://blog.csdn.net/kangear/article/details/80547073
https://blog.csdn.net/mergerly/article/details/28918081



我们在双网卡上使用的方案如下
        PREF=`ip rule list | busybox head -n 2 | busybox tail -n 1 | busybox awk '{print $1}' | busybox sed 's/://g'`
        let PREF--
        ip rule add from all table 1 pref ${PREF}
        ip route add 192.168.0.0/24 via 192.168.0.1 dev eth0 table 1

        via应该就是from + to

##########################################################################################################################
0010                                                    Imx8qm平台下spi_norflash启动
##########################################################################################################################
思路是这样：
    板子本身是支持emmc启动。另外norflash很小。目前计划是装入U-boot即可.
    首先要保证u-boot的img放在nor_flash里面:
      我的做法是:通过dd命令写入nor_flash分区
      在android正常从emmc上启动以后;
      dd if=/dev/zero of=/dev/block/mtdblock0 
      dd if=/data/u-boot-imx8qm.imx of=/dev/block/mtdblock0 bs=1k seek=4 
      dd if=/data/qspi-header of=/dev/block/mtdblock0 bs=1k seek=1

这里面: 

      1. u-boot-imx8qm.imx编译的时候需要修改参数,目标文件是device/fsl/vinson/AndroidUboot.mk
             device/fsl/vinson/AndroidUboot.mk:
                     cp  $(FSL_PROPRIETARY_PATH)/fsl-proprietary/uboot-firmware/imx8q/mx$$SCFW_PLATFORM-scfw-tcm.bin $(IMX_MKIMAGE_PATH)/imx-mkimage/$$MKIMAGE_PLATFORM/scfw_tcm.bin; \
                     cp  $(FSL_PROPRIETARY_PATH)/fsl-proprietary/uboot-firmware/imx8q/bl31-$(strip $(2)).bin $(IMX_MKIMAGE_PATH)/imx-mkimage/$$MKIMAGE_PLATFORM/bl31.bin; \
                     $(MAKE) -C $(IMX_MKIMAGE_PATH)/imx-mkimage/ clean; \
                     $(MAKE) -C $(IMX_MKIMAGE_PATH)/imx-mkimage/ SOC=$$MKIMAGE_PLATFORM flash; \
                     cp $(IMX_MKIMAGE_PATH)/imx-mkimage/$$MKIMAGE_PLATFORM/flash.bin $(PRODUCT_OUT)/u-boot-$(strip $(2)).imx;
            +        $(MAKE) -C $(IMX_MKIMAGE_PATH)/imx-mkimage/ clean; \
            +        $(MAKE) -C $(IMX_MKIMAGE_PATH)/imx-mkimage/ SOC=$$MKIMAGE_PLATFORM flash_flexspi; \
            +        cp $(IMX_MKIMAGE_PATH)/imx-mkimage/$$MKIMAGE_PLATFORM/flash.bin $(PRODUCT_OUT)/u-boot-$(strip $(2))_flexspi.imx;
             endef
        生成需要的flex_spi uboot

      2. 需要在boot之前的地址增加qspi-header的文件：   
            qspi-header是根据mfg里面的ucl2_classic.xml里面的命令生成的
                                                            [源文件是qspi-header.sh.tar,ucl2_classic.xml,都在mfg工具里面]
                                                            qspi包里面还有指定nor_flash的config文件

    <CMD state="Updater" type="push" body="$ tar xf $FILE "> Extracting...</CMD>
    <CMD state="Updater" type="push" body="send" file="files/%norconfig%">Sending QSPI header config file</CMD>
    <CMD state="Updater" type="push" body="$ sh qspi-header.sh $FILE"> Generating the ascii value header</CMD>
    <!--hexdump to convert ascii value to hex file-->
    <CMD state="Updater" type="push" body="$ busybox hexdump -R qspi-tmp > qspi-header">Converting ascii value to hex file</CMD>
    <CMD state="Updater" type="push" body="$ dd if=qspi-header of=/dev/mtd0 bs=1k seek=1" ifdev="MX6SX MX6UL MX6ULL">Writing header to NOR flash</CMD>


    
      3. 硬件是要短接，保证走spi流程启动[需要跳帽]

      4.代码逻辑修改
      修改:
uboot/arch/arm/cpu/armv8/imx8/cpu.c
@@ -802,6 +802,7 @@ int mmc_get_env_dev(void)
     
            switch(dev_rsrc) {
            case SC_R_SDHC_0:
    +       case SC_R_FSPI_0:
                   devno = 0;
                   break;
            case SC_R_SDHC_1:
                                            

uboot/common/image-android.c
@@ -109,7 +109,7 @@ int android_image_get_kernel(const struct andr_img_hdr *hdr, int verify,
                sprintf(newbootargs,
                        " androidboot.storage_type=sd");
        } else if (bootdev == MMC1_BOOT || bootdev == MMC2_BOOT ||
                bootdev == MMC3_BOOT || bootdev == MMC4_BOOT) {
+               bootdev == MMC3_BOOT || bootdev == MMC4_BOOT || bootdev == FLEXSPI_BOOT) {
                sprintf(newbootargs,
                        " androidboot.storage_type=emmc");
        } else if (bootdev == NAND_BOOT) {
                                    

uboot/drivers/usb/gadget/f_fastboot.c
    @@ -1189,6 +1189,7 @@ void board_fastboot_setup(void)
            case MMC2_BOOT:
            case MMC3_BOOT:
            case MMC4_BOOT:
    +       case FLEXSPI_BOOT:
                    dev_no = mmc_get_env_dev();
                    sprintf(boot_dev_part,"mmc%d",dev_no);
                    if (!getenv("fastboot_dev"))


##########################################################################################################################
0011                                                    增加fastboot下关于bootloader_nor分区以及刷写
##########################################################################################################################
在10的逻辑下已经可以保证启动正常。
所以要在fastboot的功能里面实现烧写flexspi的uboot到nor_flash上面。

修改:
    uboot/drivers/usb/gadget/f_fastboot.c
    @@ -25,6 +25,9 @@
     #include <linux/compiler.h>
     #include <version.h>
     #include <g_dnl.h>
    +#include <spi.h>
    +#include <spi_flash.h>
    +#include <dm/device-internal.h>
     #ifdef CONFIG_FASTBOOT_FLASH_MMC_DEV
     #include <fb_mmc.h>
     #endif
    @@ -234,6 +237,9 @@ static struct usb_gadget_strings *fastboot_strings[] = {
     #define TEE_HWPARTITION_ID 2
     #endif
     
        +#define ANDROID_BOOTLOADER_NOR_OFFSET  0x0        //0 offset
        +#define ANDROID_BOOTLOADER_NOR_SIZE    0x100000   //1MB size
         #define ANDROID_MBR_OFFSET         0
         #define ANDROID_MBR_SIZE           0x200
         #ifdef  CONFIG_BOOTLOADER_OFFSET_33K
    @@ -259,8 +265,11 @@ struct fastboot_device_info fastboot_devinfo;
     enum {
          PTN_GPT_INDEX = 0,
          PTN_TEE_INDEX,
+         PTN_BOOTLOADER_NOR_INDEX,
          PTN_BOOTLOADER_INDEX,
+         PTN_MAX_INDEX,
        };

          static unsigned int download_bytes_unpadded;
      
      static struct cmd_fastboot_interface interface = {
    @@ -639,6 +648,60 @@ int write_backup_gpt(void)
            return 0;
    }
       
    +int save_img_to_nor(uchar *buff, u32 start_address, size_t len)
    +{
    +#if 1
    +#ifdef CONFIG_DM_SPI_FLASH
    +       int ret = 0;
    +       unsigned int bus = 0;
    +       unsigned int cs = 0;
    +       unsigned int speed = 29000000;
    +       unsigned int mode = 0;
    +    struct spi_flash *flash;
    +       struct udevice *new, *bus_dev;
    +
    +       /* Remove the old device, otherwise probe will just be a nop */
    +       ret = spi_find_bus_and_cs(bus, cs, &bus_dev, &new);
    +       if (!ret) {
    +               device_remove(new);
    +       }
    +       flash = NULL;
    +       ret = spi_flash_probe_bus_cs(bus, cs, speed, mode, &new);
    +       if (ret) {
    +               printf("Failed to initialize SPI flash at %u:%u (error %d)\n",
    +                      bus, cs, ret);
    +               return 1;
    +       }else
    +               {
    +               printf(" Initialize SPI flash at %u:%u with speed %u; mode %u(success %d)\n",
    +                      bus, cs, speed, mode, ret);
    +               };
    +
    +       flash = dev_get_uclass_priv(new);
    +
    +       ret = spi_flash_erase(flash, start_address , len);
    +       printf("SF: %zu bytes @ %#x Erased: %s\n", (size_t)len, (u32)start_address,
    +              ret ? "ERROR" : "OK");
    +       if (ret) {
    +               printf("SPI flash erase failed\n");
    +               return 1;
    +       }
    +
    +       ret = spi_flash_write(flash, start_address, len, buff);
    +       printf("SF: %zu bytes @ %#x : Written\n", (size_t)len, (u32)start_address);
    +       if (ret) {
    +               printf("SPI flash write failed\n");
    +               return 1;
    +       }
    +#endif
    +       return ret;
    +#endif
    +    printf("save_img_to_nor back\n");
    +    return 0;
    +}
    +
    +
     static void process_flash_mmc(const char *cmdbuf)
      {
                  if (download_bytes) {
    @@ -660,6 +723,16 @@ static void process_flash_mmc(const char *cmdbuf)
                    ptn = fastboot_flash_find_ptn(cmdbuf);
                    if (ptn == NULL) {
                            fastboot_fail("partition does not exist");
    +               } else if (memcmp(ptn->name, "bootloader_nor", 14) == 0){
    +                               printf("writing to partition '%s'\n", ptn->name);
    +
    +                       if (save_img_to_nor(interface.transfer_buffer, ptn->start, ptn->length)) {
    +                               printf("Writing '%s' FAILED!\n", ptn->name);
    +                               fastboot_fail("Write partition");
    +                       } else {
    +                               printf("Writing '%s' DONE!\n", ptn->name);
    +                               fastboot_okay("OKAY");
    +                       }
                    } else if ((download_bytes >
                               ptn->length * MMC_SATA_BLOCK_SIZE) &&
                                        !(ptn->flags & FASTBOOT_PTENTRY_FLAGS_WRITE_ENV)) {
    @@ -967,7 +1040,7 @@ static int _fastboot_parts_add_ptable_entry(int ptable_index,
                    if (part_get_info(dev_desc,
                                            mmc_dos_partition_index, &info)) {
                            debug("Bad partition index:%d for partition:%s\n",
    -                      mmc_dos_partition_index, name);
    +                      mmc_dos_partition_index, (const char *)info.name);
                                         return -1;
                                                 }
                                 ptable[ptable_index].start = info.start;
    @@ -1072,6 +1145,11 @@ static int _fastboot_parts_load_from_ptable(void)
                ptable[PTN_TEE_INDEX].partition_id = TEE_HWPARTITION_ID;
            strcpy(ptable[PTN_TEE_INDEX].fstype, "raw");
             
    +   /* Bootloader_nor */
    +    strcpy(ptable[PTN_BOOTLOADER_NOR_INDEX].name, "bootloader_nor");
    +    ptable[PTN_BOOTLOADER_NOR_INDEX].start = ANDROID_BOOTLOADER_NOR_OFFSET;
    +    ptable[PTN_BOOTLOADER_NOR_INDEX].length = ANDROID_BOOTLOADER_NOR_SIZE;
    +
        /* Bootloader */
         strcpy(ptable[PTN_BOOTLOADER_INDEX].name, FASTBOOT_PARTITION_BOOTLOADER);
         ptable[PTN_BOOTLOADER_INDEX].start =
    @@ -1085,7 +1163,7 @@ static int _fastboot_parts_load_from_ptable(void)
                int tbl_idx;
                int part_idx = 1;
                int ret;
    -       for (tbl_idx = PTN_BOOTLOADER_INDEX + 1; tbl_idx < MAX_PTN; tbl_idx++) {
    +       for (tbl_idx = PTN_MAX_INDEX; tbl_idx < MAX_PTN; tbl_idx++) {
                ret = _fastboot_parts_add_ptable_entry(tbl_idx,
                                part_idx++,
                                user_partition,
    @@ -1095,7 +1173,7 @@ static int _fastboot_parts_load_from_ptable(void)
                if (ret)
                        break;
            }
    -       for (i = 0; i <= part_idx; i++)
    +       for (i = 0; i <= tbl_idx-1; i++)
                    fastboot_flash_add_ptn(&ptable[i]);
                                 
            return 0;

    uboot/drivers/mtd/spi/spi_flash_ids.c
    @@ -135,6 +135,7 @@ const struct spi_flash_info spi_flash_ids[] = {
            {"n25q1024a",      INFO(0x20bb21, 0x0,  64 * 1024,  2048, RD_FULL | WR_QPP | E_FSR | SECT_4K) },
            {"mt25qu02g",      INFO(0x20bb22, 0x0,  64 * 1024,  4096, RD_FULL | WR_QPP | E_FSR | SECT_4K) },
            {"mt25ql02g",      INFO(0x20ba22, 0x0,  64 * 1024,  4096, RD_FULL | WR_QPP | E_FSR | SECT_4K) },
    //+       {"mt35xu256aba",   INFO(0x2c5b19, 0x0, 128 * 1024,   256, E_FSR   | SECT_4K) },
    +       {"mt35xu256aba",   INFO(0x2c5b19, 0x0, 128 * 1024,   256, E_FSR) },
            {"mt35xu512aba",   INFO(0x2c5b1a, 0x0, 128 * 1024,   512, E_FSR) },
        #endif
        #ifdef CONFIG_SPI_FLASH_SST            /* SST */


    uboot/configs/mx8qm_lpddr4_vinson_android_defconfig
        @@ -45,7 +45,8 @@ CONFIG_FSL_FSPI=y
         CONFIG_DM_SPI=y
         CONFIG_DM_SPI_FLASH=y
         CONFIG_SPI_FLASH=y
        -CONFIG_SPI_FLASH_BAR=y
        +CONFIG_QSPI_BOOT=y
        +CONFIG_SPI_FLASH_4BYTES_ADDR=y
        +CONFIG_SPI_FLASH_USE_4K_SECTORS=y
         CONFIG_SPI_FLASH_STMICRO=y
         CONFIG_CMD_SF=y
            
    uboot/arch/arm/dts/fsl-imx8qm-lpddr4-vinson.dts
    @@ -398,7 +398,7 @@
    pinctrl-0 = <&pinctrl_flexspi0>;
    status = "okay";
     
    -       flash0: mt35xu512aba@0 {
    +       flash0: mt35xu256aba@0 {
                    reg = <0>;
                    #address-cells = <1>;
                    #size-cells = <1>;
                                                

至此，fastboot支持烧写bootloader_nor分区，并且能够正常的烧写启动。
    

##########################################################################################################################
0012                                             Imx8qm Uboot build reference                                             
##########################################################################################################################
'source':
    $root/vendor/nxp-opensource/uboot-imx/

'defconfig':
    uboot目前有与kernel一样的defconfig，生成方式也与kernel基本一致;文件位置在uboot/configs里面
    首先是:
          source build/envsetup.sh
          lunch  xxxxxx
          cd $root/$uboot/
          make mx8qm_xxxx_defconfig ARCH=arm
          make menuconfig ARCH=arm
    然后就是熟悉的config配置界面

