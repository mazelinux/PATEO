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



