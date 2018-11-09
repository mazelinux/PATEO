#########################################################################
# File Name: qcom_8937.sh
# Author: maze
# Email: mazema@pateo.com.cn
# Created Time: 2018年11月06日 星期二 15时27分36秒
#########################################################################
#!/bin/bash



=============================================
======---------------------------------======
=============================================

LCD                                            ====================> 0001

=============================================
======---------------------------------======
=============================================

##########################################################################################################################
0000                                                    LCD
##########################################################################################################################
"key":

        MDSS    : 高通平台lcd multimedia Display sub system
        DSI     : Display Serial Interface
        MDP     : Mobile display processor

"MDP":

        SSPP    : Soure Surface Processor（ViG， RGB，DMA-SSPA）---格式转换和质量提升（video， graphics 等）
        LM      : Layer Mixer（LM）--混合外表面
        DSPP    : Destination Surface Processor（DSPP）---根据面板特性进行转换，校正和调整
        WB      : Write-Back/Rotation（WB）---回写到内存，如果需要还可以旋转
        Display interface--时序生成器，和外部显示设备对接    Soure Surface Processor（ViG， RGB，DMA-SSPA）---格式转换和质量提升（video， graphics 等）

"相关code路径":
        kernel/driver/video/msm/mdss/

        mdp提供图片格式转换，旋转，overlay等功能.
        dsi提供传数据.
        注意：overlay主要为了满足多界面叠加的需求，可理解为pipe，MDP支持3个overlay pipe。

"软件驱动主要分三部分":
        MDP驱动
        DSI驱动
        FrameBuffer驱动
另外还有    
        [SurfaceFlinger，Hardware Composer（HWC），以及overlay]

"probe的顺序":
        MDP probe-> DSI probe-> FB probe


"MDP probe":
        1.对使用的硬件资源进行初始化(pdev)
        2.解析devicetree
        3.创建sysfs节点
        4.同时在fb设备中注册mdp的使用接口

        rc = mdss_fb_register_mdp_instance(&mdp5);

    函数定义
        kernel/driver/video/msm/mdss/mdss_fb.c
            int mdss_fb_register_mdp_instance(struct msm_mdp_interface *mdp)

        kernel/driver/video/msm/mdss/mdss_fb.h
            struct msm_mdp_interface {

        kernel/driver/video/msm/mdss/mdss_mdp.c
            struct msm_mdp_interface mdp5 = {
                .init_fnc = mdss_mdp_overlay_init,
                .fb_mem_get_iommu_domain = mdss_fb_mem_get_iommu_domain,
                .fb_stride = mdss_mdp_fb_stride,
                .check_dsi_status = mdss_check_dsi_ctrl_status,
                .get_format_params = mdss_mdp_get_format_params,
             };

    mdss_mdp_overlay_init解析:
        1.对mdp interface 注册回调函数
        2.如果连续显示打开,调用
        kernel/driver/video/msm/mdss/mdss_mdp_overlay.c
            rc = mdss_mdp_overlay_handoff(mfd);

    mdss_mdp_overlay_handoff解析:
        kernel/driver/video/msm/mdss/mdss_mdp_overlay.c
        调用 ctl = __mdss_mdp_overlay_ctl_init(mfd);

    __mdss_mdp_overlay_ctl_init解析:
        kernel/driver/video/msm/mdss/mdss_mdp_overlay.c
        1.调用 ctl = mdss_mdp_ctl_init(pdata,mfd);
        2.对vsync_handler进行注册，以及mixer的malloc内存分配等工作

    ctl = mdss_mdp_ctl_init解析:
    根据panel的type，注册不同的控制函数


"DSI probe":
    解析panel的dtsi文件，从文件中获取到panel的mode，分辨率，帧率，command数据等(pdev)


"FB  probe":
    1.从dsi的数据结构中获得panel的相关信息(pdev)
    2.注册fb
    3.对mdp做初始化
      if (mfd->mdp.init_fnc) {   //init_fnc为mdss_mdp_overlay_init
        rc = mfd->mdp.init_fnc(mfd);
        if (rc) {
            pr_err("init_fnc failed\n");
            return rc;
            }
      }

    4.对lcd使用的背光进行注册
         if (!lcd_backlight_registered) {
             backlight_led.brightness = mfd->panel_info->brightness_max;
             backlight_led.max_brightness = mfd->panel_info->brightness_max;
             if (led_classdev_register(&pdev->dev, &backlight_led))
                 pr_err("led_classdev_register failed\n");
             else
                 lcd_backlight_registered = 1;
         }



##########################################################################################################################
lcd :bringup sim8930l 
    硬件上.1280*720的lvds屏幕+max9278加串器+max9283解串器

    1.dts
    需要资源：
        lcd数据手册 '/home/maze/work/PATEO/qcom/8937/46-1%E3%80%81TM080JDHP95+Product+Spec+V1.1_.pdf' 
        lcd初始化代码
        高通lcd timing工具'/home/maze/work/PATEO/qcom/8937/80-NH713-1_R_DSI_Timing_Parameters_User_Interactive_Spreadsheet.xlsm' 
        ctrl+j --> ctrl+k
        高通lcd初始化代码转高通格式工具 '/home/maze/work/DLS-Simcom-8.1/device/qcom/common/display/tools/parser.pl' 


    需要工作
        从lcd的spec和硬件原理图获取以下信息：
        1.屏幕参数:
                屏幕类型[lvds,mipi..]

                分辨率  [1920*1080,1280*720..]

                bpp     bits per pixel  每个像素点由多少字节表示 
                [
                1位：用1个二进制位来表示颜色，这种就叫单色显示。示例就是小饭店、理发店门口的LED屏。
                8位：用8个二进制位来表示颜色，此时能表示256种颜色。这种叫灰度显示。这时候是黑白的，没有彩色，我们把纯白到纯黑分别对应255到0，中间的数值对应不同的灰。示例就是以前的黑白电视机。
                16位：用16个二进制位表示颜色，此时能表示65536种颜色。这时候就可以彩色显示了，一般是RGB565的颜色分布（用5位二进制表示红色、用6位二进制表示绿色、用5位二进制表示蓝色）。这种红绿蓝都有的颜色表示法就是一种模拟自然界中所有颜色的表示方式。但是因为RGB的颜色表达本身二进制位数不够多（导致红绿蓝三种颜色本身分的都不够细致），所以这样显示的彩色失真比较重，人眼能明显看到显示的不真实。
                24位：用24个二进制位来表示颜色，此时能表示16777216种颜色。这种表示方式和16位色原理是一样的，只是RGB三种颜色各自的精度都更高了（RGB各8位），叫RGB888，也叫RGB24。此时颜色比RGB565更加真实细腻，虽然说比自然界无数种颜色还是少了很多，不过由于人眼的不理想性所以人眼几乎不能区分1677万种颜色和无数种颜色的差别了。于是乎就把这种RGB888的表示方法叫做真彩色。（RGB565就是假彩色）
                32位：总共用32位二进制来表示颜色，其中24位表示红绿蓝三元色（还是RGB888分布），剩下8位表示透明度。这种显色方式就叫ARGB（A是阿尔法，表示透明度），现在PC机中一般都用ARGB表示颜色。
                o]

                fps  frames per second  每秒刷新多少帧

                porch values            前隐，后隐，上隐，下隐，以及换行，换页所需时间

        2.屏幕上电顺序和GPIO引脚的信号持续时间.比如reset/iovdd
        3.屏幕DSI初始化命令和后续延迟。
        4.Bitclk需要符合目标fps
        5.主机和屏幕之间的GPIO连接，包括reset.te等
        6.屏幕的功耗和电压.

    dts->msm8937-mtp.dtsi
    dts->msm8937-mdss-panels.dtsi
    驱动应该是完善的。不需要做任何改动
    参考bringup文档'/home/maze/work/PATEO/qcom/8937/SIM8950 Series Display Driver Development Guide_V1.00.docx' 

    2.加串解串
    需要资源:
        max9283/max9278 数据手册
    需要工作:
     dts->arch/arm/boot/dts/qcom/msm8937.dtsi
     driver->misc/max92xx/
     menuconfig->arch/arm/configs/msm8937_defconfig [userdebug]
