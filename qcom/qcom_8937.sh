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

LCD                                            ====================> 0000
Camera                                         ====================> 0001

=============================================
======---------------------------------======
=============================================

##########################################################################################################################
0000                                                    LCD
##########################################################################################################################
#############################################################
lk
#############################################################
lk/app/aboot/aboot.c
                                        target_display_init()接着调用gcdb_display_init()
lk/target/msm8952/target_display.c
                                        gcdb_display_init()判断lcd类型.不同类型的初始化

                                    int gcdb_display_init(const char *panel_name, uint32_t rev, void *base)
                                        if (pan_type == PANEL_TYPE_DSI) {
                                            if (update_dsi_display_config())
                                                goto error_gcdb_display_init;
                                                target_dsi_phy_config(&dsi_video_mode_phy_db);
                                                mdss_dsi_check_swap_status();
                                                mdss_dsi_set_pll_src();
                                                if (dsi_panel_init(&(panel.panel_info), &panelstruct)) {    //dsi panel init逻辑
                                                        dprintf(CRITICAL, "DSI panel init failed!\n");
                                                        ret = ERROR;
                                                        goto error_gcdb_display_init;
                                                }
                                                panel.panel_info.mipi.mdss_dsi_phy_db = &dsi_video_mode_phy_db;
                                                panel.pll_clk_func = mdss_dsi_panel_clock;
                                                panel.dfps_func = mdss_dsi_mipi_dfps_config;
                                                panel.power_func = mdss_dsi_panel_power;
                                                panel.pre_init_func = mdss_dsi_panel_pre_init;
                                                panel.bl_func = mdss_dsi_bl_enable;
                                                panel.dsi2HDMI_config = mdss_dsi2HDMI_config;/** Reserve fb memory to store pll codes and pass* pll codes values to kernel.*/
                                                panel.panel_info.dfps.dfps_fb_base = base;
                                                base += DFPS_PLL_CODES_SIZE;
                                                panel.fb.base = base;
                                                dprintf(SPEW, "dfps base=0x%p,d, fb_base=0x%p!\n",
                                                panel.panel_info.dfps.dfps_fb_base, base);
                                                panel.fb.width =  panel.panel_info.xres;
                                                panel.fb.height =  panel.panel_info.yres;
                                                panel.fb.stride =  panel.panel_info.xres;
                                                panel.fb.bpp =  panel.panel_info.bpp;
                                                panel.fb.format = panel.panel_info.mipi.dst_format;
                                        }
                                        .......
                                        ret = msm_display_init(&panel);

lk/dev/gcdb/display/gcdb_display.c
lk/dev/gcdb/display/panel_display.c
                                        dsi_panel_init的初始化逻辑.
                                        int dsi_panel_init(struct msm_panel_info *pinfo,struct panel_struct *pstruct)
                                        {
                                            /* Resolution setting*/
                                            pinfo->xres = pstruct->panelres->panel_width;
                                            pinfo->yres = pstruct->panelres->panel_height;
                                            pinfo->lcdc.h_back_porch = pstruct->panelres->hback_porch;
                                            pinfo->lcdc.h_front_porch = pstruct->panelres->hfront_porch;
                                            pinfo->lcdc.h_pulse_width = pstruct->panelres->hpulse_width;
                                            pinfo->lcdc.v_back_porch = pstruct->panelres->vback_porch;
                                            pinfo->lcdc.v_front_porch = pstruct->panelres->vfront_porch;
                                            pinfo->lcdc.v_pulse_width = pstruct->panelres->vpulse_width;
                                            pinfo->lcdc.hsync_skew = pstruct->panelres->hsync_skew;

                                            pinfo->border_top = pstruct->panelres->vtop_border;
                                            pinfo->border_bottom = pstruct->panelres->vbottom_border;
                                            pinfo->border_left = pstruct->panelres->hleft_border;
                                            pinfo->border_right = pstruct->panelres->hright_border;

                                            ....
                                            pinfo->xres += (pinfo->border_left + pinfo->border_right);
                                            pinfo->yres += (pinfo->border_top + pinfo->border_bottom);

                                            ....
                                            if (pstruct->paneldata->panel_operating_mode & DUAL_PIPE_FLAG)
                                                pinfo->lcdc.dual_pipe = 1;
                                            if (pstruct->paneldata->panel_operating_mode & PIPE_SWAP_FLAG)
                                                pinfo->lcdc.pipe_swap = 1;
                                            if (pstruct->paneldata->panel_operating_mode & SPLIT_DISPLAY_FLAG)
                                                pinfo->lcdc.split_display = 1;
                                            if (pstruct->paneldata->panel_operating_mode & DST_SPLIT_FLAG)
                                                pinfo->lcdc.dst_split = 1;
                                            if (pstruct->paneldata->panel_operating_mode & DUAL_DSI_FLAG)
                                                pinfo->mipi.dual_dsi = 1;
                                            if (pstruct->paneldata->panel_operating_mode & USE_DSI1_PLL_FLAG)
                                                pinfo->mipi.use_dsi1_pll = 1;

                                            ....
                                            /* Color setting*/
                                            pinfo->lcdc.border_clr = pstruct->color->border_color;
                                            pinfo->lcdc.underflow_clr = pstruct->color->underflow_color;
                                            pinfo->mipi.rgb_swap = pstruct->color->color_order;
                                            pinfo->bpp = pstruct->color->color_format;
                                            switch (pinfo->bpp) {
                                                case BPP_16:
                                                    ...
                                                case BPP_18:
                                                    ...
                                                case BPP_24:
                                                default:
                                                    pinfo->mipi.dst_format = DSI_VIDEO_DST_FORMAT_RGB888;
                                                    break;
                                            }

                                            /* Panel generic info */
                                            pinfo->mipi.mode = pstruct->paneldata->panel_type;
                                            if (pinfo->mipi.mode) {
                                                pinfo->type = MIPI_CMD_PANEL;
                                            } else {
                                                pinfo->type = MIPI_VIDEO_PANEL;
                                            }
                                            pinfo->clk_rate = pstruct->paneldata->panel_clockrate;
                                            pinfo->orientation = pstruct->paneldata->panel_orientation;
                                            pinfo->mipi.interleave_mode = pstruct->paneldata->interleave_mode;
                                            pinfo->mipi.broadcast = pstruct->paneldata->panel_broadcast_mode;
                                            pinfo->mipi.vc = pstruct->paneldata->dsi_virtualchannel_id;
                                            pinfo->mipi.frame_rate = pstruct->paneldata->panel_framerate;
                                            pinfo->mipi.stream = pstruct->paneldata->dsi_stream;
                                            pinfo->mipi.mode_gpio_state = pstruct->paneldata->mode_gpio_state;
                                            pinfo->mipi.bitclock = pstruct->paneldata->panel_bitclock_freq;
                                            if (pinfo->mipi.bitclock) {
                                                /* panel_clockrate is depcrated in favor of bitclock_freq */
                                                pinfo->clk_rate = pinfo->mipi.bitclock;
                                            }
                                            pinfo->mipi.use_enable_gpio =
                                                pstruct->paneldata->panel_with_enable_gpio;
                                            ret = dsi_panel_ctl_base_setup(pinfo,
                                                    pstruct->paneldata->panel_destination);

                                            /* Video Panel configuration */
                                            pinfo->mipi.pulse_mode_hsa_he = pstruct->videopanel->hsync_pulse;
                                            pinfo->mipi.hfp_power_stop = pstruct->videopanel->hfp_power_mode;
                                            pinfo->mipi.hbp_power_stop = pstruct->videopanel->hbp_power_mode;
                                            pinfo->mipi.hsa_power_stop = pstruct->videopanel->hsa_power_mode;
                                            pinfo->mipi.eof_bllp_power_stop = pstruct->videopanel->bllp_eof_power_mode;
                                            pinfo->mipi.bllp_power_stop = pstruct->videopanel->bllp_power_mode;
                                            pinfo->mipi.traffic_mode = pstruct->videopanel->traffic_mode;
                                            pinfo->mipi.eof_bllp_power = pstruct->videopanel->bllp_eof_power;

                                            /* Command Panel configuratoin */
                                            ....
                                            /* Data lane configuraiton */
                                            pinfo->mipi.num_of_lanes = pstruct->laneconfig->dsi_lanes;
                                            pinfo->mipi.data_lane0 = pstruct->laneconfig->lane0_state;
                                            pinfo->mipi.data_lane1 = pstruct->laneconfig->lane1_state;
                                            pinfo->mipi.data_lane2 = pstruct->laneconfig->lane2_state;
                                            pinfo->mipi.data_lane3 = pstruct->laneconfig->lane3_state;
                                            pinfo->mipi.lane_swap = pstruct->laneconfig->dsi_lanemap;
                                            pinfo->mipi.force_clk_lane_hs = 1;//pstruct->laneconfig->force_clk_lane_hs;

                                            pinfo->mipi.t_clk_post = pstruct->paneltiminginfo->tclk_post;
                                            pinfo->mipi.t_clk_pre = pstruct->paneltiminginfo->tclk_pre;
                                            pinfo->mipi.mdp_trigger = pstruct->paneltiminginfo->dsi_mdp_trigger;
                                            pinfo->mipi.dma_trigger = pstruct->paneltiminginfo->dsi_dma_trigger;
                                            pinfo->fbc.comp_ratio = 1;

                                            if (pinfo->compression_mode == COMPRESSION_DSC) {
                                                struct dsc_desc *dsc = &pinfo->dsc;
                                                struct dsc_parameters *dsc_params = NULL;

                                                dsc_params = pstruct->config->dsc;
                                                ...
                                                dsc->major = dsc_params->major;
                                                dsc->minor = dsc_params->minor;
                                                dsc->scr_rev = dsc_params->scr_rev;
                                                dsc->pps_id = dsc_params->pps_id;
                                                dsc->slice_height = dsc_params->slice_height;
                                                dsc->slice_width = dsc_params->slice_width;
                                                dsc->bpp = dsc_params->bpp;
                                                dsc->bpc = dsc_params->bpc;
                                                dsc->slice_per_pkt = dsc_params->slice_per_pkt;
                                                dsc->block_pred_enable = dsc_params->block_prediction;
                                                dsc->enable_422 = 0;
                                                dsc->convert_rgb = 1;
                                                dsc->vbr_enable = 0;

                                                if (dsc->parameter_calc)
                                                    dsc->parameter_calc(pinfo);
                                            } else if (pinfo->compression_mode == COMPRESSION_FBC) {
                                                pinfo->fbc.enabled = pstruct->fbcinfo.enabled;
                                                if (pinfo->fbc.enabled) {
                                                    pinfo->fbc.comp_ratio= pstruct->fbcinfo.comp_ratio;
                                                    pinfo->fbc.comp_mode = pstruct->fbcinfo.comp_mode;
                                                    pinfo->fbc.qerr_enable = pstruct->fbcinfo.qerr_enable;
                                                    pinfo->fbc.cd_bias = pstruct->fbcinfo.cd_bias;
                                                    pinfo->fbc.pat_enable = pstruct->fbcinfo.pat_enable;
                                                    pinfo->fbc.vlc_enable = pstruct->fbcinfo.vlc_enable;
                                                    pinfo->fbc.bflc_enable = pstruct->fbcinfo.bflc_enable;
                                                    pinfo->fbc.line_x_budget = pstruct->fbcinfo.line_x_budget;
                                                    pinfo->fbc.block_x_budget = pstruct->fbcinfo.block_x_budget;
                                                    pinfo->fbc.block_budget = pstruct->fbcinfo.block_budget;
                                                    pinfo->fbc.lossless_mode_thd = pstruct->fbcinfo.lossless_mode_thd;
                                                    pinfo->fbc.lossy_mode_thd = pstruct->fbcinfo.lossy_mode_thd;
                                                    pinfo->fbc.lossy_rgb_thd = pstruct->fbcinfo.lossy_rgb_thd;
                                                    pinfo->fbc.lossy_mode_idx = pstruct->fbcinfo.lossy_mode_idx;
                                                    pinfo->fbc.slice_height = pstruct->fbcinfo.slice_height;
                                                    pinfo->fbc.pred_mode = pstruct->fbcinfo.pred_mode;
                                                    pinfo->fbc.max_pred_err = pstruct->fbcinfo.max_pred_err;
                                                }
                                            }

                                            pinfo->pre_on = dsi_panel_pre_on;
                                            pinfo->pre_off = dsi_panel_pre_off;
                                            pinfo->on = dsi_panel_post_on;
                                            pinfo->off = dsi_panel_post_off;
                                            pinfo->rotate = dsi_panel_rotation;
                                            pinfo->config = dsi_panel_config;
                                        }

msm_shared/display.c
                                        int msm_display_init(struct msm_fb_panel_data *pdata)    
#############################################################
kernel
#############################################################
"key":
        Acronym             Definition
        CLK     : Click
        CMD     : Command
        DCS     : Digital Cellular System
        D-PHY   : Display Serial Interface Physical Layer
        DSI     : Display Serial Interface
        DTS     : Digital Test Sequence
        GCDB    : Global Component Database
        GPIO    : General Purpose Input/Output
        HS      : High Speed
        HW      : Hardware
        IC      : Integrated Circuit
        LCD     : Liquid Crystal Display
        LK      : Little Kernel
        MDSS    : 高通平台lcd multimedia Display sub system
        DSI     : Display Serial Interface
        MDP     : Mobile display processor
        MIPI    : Mobile Industry Processor Interface
        OEM     : Original Equipment Manufacturer
        PHY     : Physical Layer
        PMIC    : Power Management Integrated Circuit
        PWM     : Pulse Width Modulation
        TE      : Terminal Emulator
        XML     : eXtensible Markup Language

"MDP":

        SSPP    : Soure Surface Processor（ViG， RGB，DMA-SSPA）---格式转换和质量提升（video， graphics 等）
        LM      : Layer Mixer（LM）--混合外表面
        DSPP    : Destination Surface Processor（DSPP）---根据面板特性进行转换，校正和调整
        WB      : Write-Back/Rotation（WB）---回写到内存，如果需要还可以旋转
        Display interface--时序生成器，和外部显示设备对接   
        Soure Surface Processor（ViG， RGB，DMA-SSPA）---格式转换和质量提升（video， graphics 等）

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

        kernel/drivers/video/msm/mdss/mdss_mdp.c
            static int mdss_mdp_probe(struct platform_device *pdev)

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
        lcd数据手册                     '/home/maze/work/PATEO/qcom/8937/46-1%E3%80%81TM080JDHP95+Product+Spec+V1.1_.pdf' 

        lcd初始化代码

        高通lcd timing工具              '/home/maze/work/PATEO/qcom/8937/80-NH713-1_R_DSI_Timing_Parameters_User_Interactive_Spreadsheet.xlsm' 
        ctrl+j --> ctrl+k

        高通lcd devicetree 生成工具     '/home/maze/work/DLS-Simcom-8.1/device/qcom/common/display/tools/parser.pl' 
        device tree 参数解析文档        '/home/maze/work/DLS-Simcom-8.1/kernel/Documentations/devicetree/bindings/fb/mdss-dsi-panel.txt'
        命令:perl parser.pl <sourec xml file OEM edit> panel                                        ---->生成dsi-panel<vendor>-xxx-xxx.dtsi 和 panel_<vendor>_xxx_xxx.h


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
                   '/home/maze/work/PATEO/qcom/8937/lm80-p0436-4_dsi_display_porting_guide.pdf' 



    2.加串解串
    需要资源:
        max9283/max9278 数据手册
    需要工作:
     dts->arch/arm/boot/dts/qcom/msm8937.dtsi
     driver->misc/max92xx/
     menuconfig->arch/arm/configs/msm8937_defconfig [userdebug]





# Add busybox:
        PRODUCT_COPY_FILES += \
            external/devlib/devlib/bin/armeabi/busybox:root/sbin/busybox


##########################################################################################################################
0001                                                    Camera
##########################################################################################################################
1.最下面的是kernel层的驱动,其中按照V4L2架构实现了camera sensor等驱动,向用户空间提供/dev/video0节点;由于高通将大部分驱动逻辑代码放到了HAL层,因此在kernel部分只进行了V4L2的设备注册、IIC设备驱动等基本动作。
2.在往上是HAL层,高通代码实现了对/dev/video0的基本操作,对接了android的camera相关的interface。(ps,HAL层的库中也封装了sensor端一些核心逻辑代码。将驱动的操作逻辑放在HAL层是为了避免linux的开源属性对厂商私有技术的泄露)
3.再往上就是android的架构对camera的处理

camera在kernel层的主文件为msm.c,负责设备的具体注册及相关方法的填充;

Kernel:
kernel/drvier/media/platform/msm/camera_v2/

摄像头内核驱动包含两个主文件。必要时,可添加更多日志以方便调试:

    kernel/drivers/media/platform/msm/camera_v2/msm.c
    1.创建 MSM 芯片组配置节点
    2.设置会话队列
    3.将事件发到 mm-camera 后端并等待答复
    4.管理 V4L2 数据流和缓存
    kernel/drivers/media/platform/msm/camera_v2/camera/camera.c
    1.开机时创建视频设备节点
    2.包含服务于 V4L2 IOCTL 和文件操作的函数
    3.创建会话和数据流

kernel层对于不同的sensor对应自己的同一个驱动文件 — msm_sensor_driver.c,主要是把vendor下面的sensor_lib_t的设定填充到msm_sensor_ctrl_t中
        msm_sensor_driver.c
            msm_sensor_driver_init
                platform_driver_register(&msm_sensor_platform_driver);
                    .probe = msm_sensor_driver_platform_probe   //解析dts里面参数 //注册cci/i2c从设备.初始化通信逻辑 //初始化sensor功能函数
                i2c_add_driver(&msm_sensor_driver_i2c);
                    .probe  = msm_sensor_driver_i2c_probe       //操作与platform probe一样

在msm_sensor_init.c中主要是一些IOCTL处理,处理vendor传下来的IOCTL,vendor下面的power_setting,ret_setting等信息都是通过这里的ioctl传下来的
        msm_sensor_init.c
            msm_sensor_init_module                              //Create /dev/v4l-subdevX for msm_sensor_init 
            msm_sensor_driver_cmd
                msm_sensor_driver_probe                         //异常重要.sensor的上下电逻辑,/dev/videox字符实现,v4l2_subdev结构的注册等等,均在这里


在msm_sensor.c文件中,主要维护高通自己的一个sensor相关结构体—msm_sensor_ctrl_t,同时把dts文件中的配置信息读取出来;msm_sensor.c异常重要,基本可以理解为sensor驱动的逻辑都在这里面;probe逻辑,上下电逻辑,msm_sensor_ctrl_t包含了所有操作接口
        msm_sensor.c
        =========kernel调用顺序
        msm_sensor_power_up
        msm_sensor_config
        msm_sensor_subdev_ioctl
        =========用户空间调用顺序

=========================================================================
开机过程中 kernel 层的sensorprobe逻辑是
 msm.c
    msm_init
    ##msm_probe start
      msm_probe   
        video_device_alloc              //initialize the video_device struct
        media_device_register           //register a media device       /dev/media0
        media_entity_init
        v4l2_deivce_register            //initialize the v4l2_dev struct
        video_register_device(vdev, VFL_TYPE_GRABBER, -1);          //  /dev/video0 -->注册video device，VFL_TYPE_GRABBER表示注册的是视频处理设备，video_nr=-1表示自动分配从设备号,成功会在dev下生成相应的type的节点 
                                                                                            VFL_TYPE_GRABBER: 用于视频输入/输出设备的 videoX
                                                                                            VFL_TYPE_VBI: 用于垂直消隐数据的 vbiX (例如，隐藏式字幕，图文电视)
                                                                                            VFL_TYPE_RADIO: 用于广播调谐器的 radioX
                                                                                            VFL_TYPE_SUBDEV:一个子设备v4l-subdevX 
                                                                                            VFL_TYPE_SDR:Software Defined Radio swradioX
        msm_init_queue  
        cam_ahb_clk_init
    ##msm_probe end
    下面是循环逻辑,这个循环逻辑其实就是在probe各种各样的qcom.camera框架下的外围器件,序列号代表执行次数,当然这个数量是和你dts里面的配置挂钩的.分别包含:
     1                          "msm_cci_probe"             :msm/camera_v2/sensor/cci/msm_cci.c      //cci不会注册成为subdev节点!!!
     2                          "csiphy_probe"              :msm/camera_v2/sensor/csiphy/msm_csiphy.c//dts里面有2个
     3                          "csid_probe"                :msm/camera_v2/sensor/csid/msm_csid.c    //dts里面有3个
     2                          "msm_actuator_i2c_probe或者msm_actuator_platform_probe" :msm/camera_v2/sensor/actuator/msm_actuator.c
     1                          "msm_sensor_init_module"    :msm/camera_v2/sensor/msm_sensor_init.c
     1                          "cpp_probe"                 :msm/camera_v2/pproc/cpp/msm_cpp.c
     2                          "vfe_probe"                 :msm/camera_v2/isp/msm_isp_32.c
     1                          "ispif_probe"               :msm/camera_v2/ispif/msm_ispif_32.c
     1                          "msm_buf_mngr_init"         :msm/camera_v2/msm_buf_mgr/msm_generic_buf_mgr.c

    msm_sd_register        [msm_cci/msm_csiphy/msm_csid/msm_actuator/msm_sensor_init/cpp/vfe/msm_ispif/msm_buf_mngr/]
    中括号里面的设备挨个初始化,再往下的逻辑不是每个subdev都有的
    中括号里面的设备挨个初始化,再往下的逻辑不是每个subdev都有的
    msm_add_sd_in_position
    __msm_sd_register_subdev
            v4l2_device_register_subdev     //initialize the v4l2_subdev struct
            __video_register_device(vdev, VFL_TYPE_SUBDEV, -1, 1,sd->owner);   //  /dev/v4l2-subdev 0.1.2.3.4.5.6.7.8.9.10.11.12 -->注册video_device节点 /dev/v4l-subdevX
    msm_cam_get_v4l2_subdev_fops_ptr
    msm_cam_copy_v4l2_subdev_fops
    msm_sd_notify
    msm_sd_find
    循环结束
=========================================================================


=========================================================================
单独看msm_sersor_init的逻辑线
##msm_sensor_init_module start
 msm_sensor_init.c
     msm_sensor_init_module
        v4l2_subdev_init(&s_init->msm_sd.sd, &msm_sensor_init_subdev_ops);
        media_entity_init(&s_init->msm_sd.sd.entity, 0, NULL, 0);
        msm_sd_register                                                            /dev/v4l2-subdev7
##msm_sensor_init_module end

##msm_sensor_driver_init start
 msm_sensor_driver.c
 msm_sensor_driver_init
     msm_sensor_driver_platform_probe 或者 msm_sensor_driver_i2c_probe  [两者的区别因该是一个走cci总线,一个走标准的i2c总线]
        msm_sensor_driver_parse
            msm_sensor_driver_get_dt_data
            msm_sensor_init_default_params
        msm_camera_get_clk_info
##msm_sensor_driver_init end
=========================================================================


=========================================================================
initrc启动server的逻辑是

##上层下发probewait命令
 msm_sensor_init.c
    msm_sensor_init_subdev_ioctl
        case VIDIOC_MSM_SENSOR_INIT_CFG:
        msm_sensor_driver_cmd
            case CFG_SINIT_PROBE_WAIT_DONE:
            msm_sensor_wait_for_probe_done
                wait_event_timeout
##上层下发probewait命令结束

##上层打开video节点
 msm.c
    msm_open           [open /dev/videoX]
        v4l2_fh_open                            ///* create event queue */调用v4l2_fh_open函数打开Camera,该函数会创建event队列等进行一些其他操作
            v4l2_fh_init
            v4l2_fh_add
        msm_pm_qos_add_request                  //register msm_v4l2_pm_qos_request
            pm_qos_add_request

##上层下发probe命令                    
 msm_sensor_init.c
    msm_sensor_init_subdev_ioctl
        case VIDIOC_MSM_SENSOR_INIT_CFG:
        msm_sensor_driver_cmd
            case CFG_SINIT_PROBE:
            msm_sensor_driver_probe

 msm_sensor_driver.c
    msm_sensor_driver_probe
        msm_sensor_get_power_settings
            msm_sensor_get_power_up_settings
            msm_sensor_get_power_down_settings
        msm_camera_fill_vreg_params             ///* Parse and fill vreg params for powerup settings */
        msm_camera_fill_vreg_params             ///* Parse and fill vreg params for powerdown settings*/
        msm_sensor_fill_eeprom_subdevid_by_name //Update eeporm subdevice Id by input eeprom name
        msm_sensor_fill_actuator_subdevid_by_name //Update actuator subdevice Id by input actuator name
        msm_sensor_fill_ois_subdevid_by_name
        msm_sensor_fill_flash_subdevid_by_name
        sensor_power_up                             //msm_sensor.c .sensor_power_up = msm_sersor_power_up  /* Power up and probe sensor */

 msm_sensor.c
    msm_sersor_power_up
        msm_sensor_adjust_mclk
        msm_camera_tz_i2c_power_up
        msm_camera_power_up
            msm_camera_pinctrl_init
            msm_camera_request_gpio_table
            pinctrl_select_state
            case SENSOR_CLK:
                msm_camera_clk_enable
            case SENSOR_GPIO:
            case SENSOR_VREG:
                msm_cam_sensor_handle_reg_gpio
            case SENSOR_I2C_MUX:
    msm_sensor_check_id
        msm_sensor_match_id
            msm_sensor_id_by_mask

 msm_sensor_driver.c
    msm_sensor_driver_create_v4l_subdev
        camera_init_v4l2
            video_device_alloc
            media_device_register   //注册media_device节点  /dev/media1
            media_entity_init
            v4l2_device_register
            video_register_device   //注册video_device节点  /dev/video1
            device_init_wakeup
        v4l2_subdev_init            
        v4l2_set_subdevdata
        media_entity_init
        msm_sd_register             //msm.c msm_sd_register

 msm.c
    msm_sd_register                 //具体的摄像头sensor, tw9992
        msm_add_sd_in_position
        __msm_sd_register_subdev
            v4l2_device_register_subdev     //initialize the v4l2_subdev struct
            __video_register_device(vdev, VFL_TYPE_SUBDEV, -1, 1,sd->owner);    //注册video_device节点 /dev/v4l-subdev13
    msm_cam_get_v4l2_subdev_fops_ptr
    msm_cam_copy_v4l2_subdev_fops

 msm_sensor.c
    msm_sensor_power_down           ///* Power down */ msm_sensor.c .sensor_power_down = msm_sersor_power_down 
        msm_camera_power_down
            case SENSOR_CLK:
                msm_camera_clk_enable
            case SENSOR_GPIO:
            case SENSOR_VREG:
                msm_camera_get_power_settings
                msm_cam_sensor_handle_reg_gpio
            case SENSOR_I2C_MUX:
    msm_sensor_fill_slave_info_init_params
    msm_sensor_validate_slave_info
    msm_sensor_fill_sensor_info     ///*Save sensor info*/
    kobject_create_and_add("camera", kernel_kobj)
    sysfs_create_group(&s_ctrl->pdev->dev.kobj, &pateo_msm_attr_group);
    msm_subscribe_event
    .
    .
    .
                    // 最终就是调用msm_camera_power_up上电，msm_sensor_match_id识别sensor id，调用tw9992 probe()探测函数去完成匹配设备和驱动的工作，msm_camera_power_down下电！
##上层下发probe命令结束                    

##上层下发probe_done 开始
 msm_sensor_init.c
    msm_sensor_init_subdev_ioctl
        case VIDIOC_MSM_SENSOR_INIT_CFG:
        msm_sensor_driver_cmd
            case CFG_SINIT_PROBE_DONE:
            wake_up(&s_init->state_wait);
##probe_done 结束
 msm.c                              //msm.c:1132:   .poll   = msm_poll,
    msm_poll                        //poll机制向用户层服务传递是否可以[读写的/节点是否可执行的]信号.
        poll_wait
        if (v4l2_event_pending(eventq))
            rc = POLLIN | POLLRDNORM;
    camera_v4l2_open
    msm_pm_qos_update_request
        pm_qos_update_request
    msm_create_session
        msm_init_queue(&session->command_ack_q);
        msm_init_queue(&session->stream_q);
        msm_enqueue(msm_session_q, &session->list);
    msm_create_command_ack_q
    __msm_queue_find_session
    msm_init_queue
    msm_enqueue
    msm_post_event
    __msm_queue_find_session
    __msm_queue_find_command_ack_q
    msm_poll
    msm_sensor_subdev_ioctl
    msm_sensor_config
    msm_sensor_power_up
    msm_sensor_check_id
    msm_sensor_match_id
    msm_sensor_id_by_mask
    msm_sensor_subdev_ioctl
    msm_sensor_config
    .
    .
    camera_v4l2_poll
    .


    kernel/v4l2-core/
=========================================================================

=========================================================================
                                QCOM deamon
=========================================================================
daemon进程作为单一进程，在代码中就是mm-qcamera-daemon，其main 函数的 入口，位置如下：
    /project/vendor/qcom/proprietary/mm-camera/mm-camera2/server-imaging/server.c
    1.找到服务节点的名字并打开此节点/* 1. find server node name and open the node */
        get_server_node_name(serv_al_node_name)                 //这里的serv_al_node_name为video0
            dev_fd = open(dev_name, O_RDWR | O_NONBLOCK);       //dev_name为/dev/media0
            ioctl(dev_fd, MEDIA_IOC_DEVICE_INFO, &mdev_info);   //往media0下命令
            ioctl(dev_fd, MEDIA_IOC_ENUM_ENTITIES, &entity);
                ......
        hal_fd->fd[0] = open(dev_name, O_RDWR | O_NONBLOCK);    //这里dev_name为节点名“/dev/video0”

    2.初始化模块。目前有sensor、iface、isp、stats、pproc及imglib六个模块/* 2. after open node, initialize modules */
        server_process_module_sensor_init();                    //只是初始化 modules_list[0],即执行module_sensor_init
                    static mct_module_init_name_t modules_list[] = {
                        {"sensor", module_sensor_init,   module_sensor_deinit, NULL},
                        {"iface",  module_iface_init,   module_iface_deinit, NULL},
                        {"isp",    module_isp_init,      module_isp_deinit, NULL},
                        {"stats",  stats_module_init,    stats_module_deinit, NULL},
                        {"pproc",  pproc_module_init,    pproc_module_deinit, NULL},
                        {"imglib", module_imglib_init, module_imglib_deinit, NULL},
                    };
            module_sensor_init        异常重要                  // This function creates mct_module_t for sensor module,creates port, fills capabilities and add it to the sensor module;
            函数中，通过判断entity.type == MEDIA_ENT_T_V4L2_SUBDEV &&entity.group_id == MSM_CAMERA_SUBDEV_SENSOR_INIT，找到相应的/dev/v4l-subdevX节点并打开，并通过LOG_IOCTL(fd, VIDIOC_MSM_SENSOR_INIT_CFG, &cfg)，将sensor IC的有关信息拷贝到内核空间，调用msm_sensor_driver_probe()函数，/* Power up and probe sensor */:rc = s_ctrl->func_tbl->sensor_power_up(s_ctrl);  rc为0，表明sensro I2C通信正常，接着通过msm_sensor_driver_create_i2c_v4l_subdev()，生成了/dev/media1&/dev/video1(后摄像头)和/dev/media2&/dev/video2(前摄像头)节点，并通过msm_sd_register(&s_ctrl->msm_sd)注册前后摄像头的sensor。

                mct_module_create(name);                        // name: sensor
                sensor_init_probe
                    sensor_init_eebin_probe(module_ctrl, sd_fd);或者sensor_init_xml_probe(module_ctrl, sd_fd)
                        sensor_probe
                            cfg.cfgtype = CFG_SINIT_PROBE;
                            cfg.cfg.setting = slave_info;
                            if (ioctl(fd, VIDIOC_MSM_SENSOR_INIT_CFG, &cfg) < 0) //真正调用到内核的sensorprobe逻辑的地方

        server_process_module_init();                           //执行modules_list其余部分的初始化工作

        subscribe.type = MSM_CAMERA_V4L2_EVENT_TYPE;
        ioctl(hal_fd->fd[0], VIDIOC_SUBSCRIBE_EVENT, &subscribe) //打开的文件是dev/video0,ioctl调用的是kernel/drivers/media/platform/msm/camera_v2/camera/camera.c中camera_init_v4l2函数执行的video_register_device里面的camera_v4l2_ioctl_ops里面的camera_v4l2_subscribe_event订阅事件

        mct_util_find_v4l2_subdev(probe_done_node_name)
        snprintf(probe_done_dev_name, sizeof(probe_done_dev_name), "/dev/%s",probe_done_node_name);
        open(probe_done_dev_name, O_RDWR | O_NONBLOCK);
        ioctl(probe_done_fd, VIDIOC_MSM_SENSOR_INIT_CFG, &cfg) //找到并打开对应的sub_dev节点.也就是我们最主要的sensor节点:kernel/msm-3.18/drivers/media/platform/msm/camera_v2/sensor/msm_sensor_init.c里面的ioctl:wake_up(&s_init->state_wait); 
        ...

    3.进入主循环来处理来自HAL及MCT的事件及消息，处理完之后的结果反馈给kernel（msm.c)
    typedef enum _read_fd_type {
        RD_FD_HAL, ----------------server_process_hal_event(&event)---返回真，说明消息传递给 MCT，这时不需要发送CMD ACK给kernel，因为MCT处理结束后会发出通知；反之没有，此时需要立即发送CMD ACK到kernel，以免HAL发送此消息的线程阻塞住;用来处理kernel的node update
            case MSM_CAMERA_NEW_SESSION:
                mct_controller_new();
            ...
            case MSM_CAMERA_DEL_SESSION:
                mct_controller_destory();
            ...
                mct_controller_proc_serv_msg();
                                           
        RD_DS_FD_HAL, ----------server_process_hal_ds_packet()---来自 HAL 层的消息,通过domain socket 传;用来处理mapping buffer的socket messages
                                             
        RD_PIPE_FD_MCT, ----------------server_process_mct_msg()---来自 media controller 的消息，通过pipe；用来处理mct的update buffer manager: buffer type: matedata 和frame buffers main
        RD_FD_NONE
    } read_fd_type;

    4.media controller线程
    a.概述
        MCT线程是camera新架构的引擎部分，负责对管道的监控，由此来完成一个camera设备的控制运转。它运行在daemon进程空间，由MSM_CAMERA_NEW_SESSION事件来开启，具体开启函数为server_process_hal_event--->mct_controller_new()。

    b.mct_controller_new()函数
        此函数创建一个新的MCT引擎，这将对应一个事务的pipeline。我们知道上层可以创建多个事务，每个对应一个camera，也对应自己的MCT及pipeline等。因此这个函数的主要完成以下几件事情：
        1.mct_pipeline_new()                                    ---->创建一个Pipeline及其bus，并完成pipeline函数的映射。
        2.mct_pipeline_start_session()                          ---->开启camera的所有模块并查询其能力
        3.pthread_create(..., mct_controller_thread_run, ...)   ---->创建mct线程并开始执行
        4.pthread_create(..., mct_bus_handler_thread_run, ...)  ---->创建bus处理线程

    c.MCT线程运行
        MCT整个引擎部分主要处理server及bus两类事情，对应前面提到的MCT及bus两个线程。MCT线程主要用来处理来自image server的消息，先pop MCT queue，查看是否有消息，如果有则执行mct_controller_proc_serv_msg_internal（）函数来处理。mct_controller_proc_serv_msg_internal函数用来处理来自image server的消息，并返回类型MCT_PROCESS_RET_SERVER_MSG。这里处理的消息类型主要有SERV_MSG_DS与SERV_MSG_HAL两种，分别在pipline中给出了相应的处理函数，具体查看源码可知。

    d.bus线程运行
        bus线程跟MCT线程流程一样。从代码上我们看到两个线程都是从同一个queue上面pop消息，他们是通过各自的线程条件变量来进行区分，完成线程的阻塞及运行工作。MCT的条件变量mctl_cond可以看到是在server_process.c文件中标记的，而bus的条件变量mctl_bus_handle_cond未在源码中找到标志的位置.

=========================================================================
                                QCOM CAMERA HAL
=========================================================================
源代码位于 HAL 及 mm-camera-interface 层。摄像头前端代码位于hardware/qcom/camera/QCamera2 文件夹。
摄像头前端软件位于以下子目录中:
/HAL – 包含摄像头核心 HAL 源代码
/Stack – 包含 mm-camera 及 mm-jpeg 接口源代码
/Util – 包含 HAL 所用的实用程序源代码


    1.Open camera
    App:
              mCameraManager.openCamera(currentCameraId, stateCallback, backgroundHandler);
    
    Framework:
              /frameworks/base/core/java/android/hardware/camera2/CameraManager.java    openCamera
                                                                                        -->openCameraForUid
                                                                                        ---->openCameraDeviceUserAsync    首先实例化一个CameraDeviceImpl,构造时传入了CameraDevice.StateCallback以及Handler
                                                                                                                          获取CameraDeviceCallback实例，这是提供给远端连接到CameraDeviceImpl的接口
                                                                                                                          HAL3 中走的是这一部分逻辑，主要是从CameraManagerGlobal中获取CameraService的本地接口，通过它远端调用(采用Binder机制)connectDevice方法连接到相机设备。注意返回的cameraUser实际上指向的是远端CameraDeviceClient的本地接口.将CameraDeviceClient设置到CameraDeviceImpl中进行管理

    Runtime:
              /frameworks/av/services/camera/libcameraservice/CameraService.cpp       connectDevice        调用的 connectHelper 方法才真正实现了连接逻辑（HAL1 时最终也调用到这个方法）。需要注意的是，设定的模板类型是 ICameraDeviceCallbacks 以及 CameraDeviceClient;client指向的类型是CameraDeviceClient，其实例则是最终的返回结果
                                                                                    -->connectHelper     调用 makeClient 生成 CameraDeviceClient 实例;初始化 CLIENT 实例。注意此处的模板类型 CLIENT 即是 CameraDeviceClient，传入的参数 mCameraProviderManager 则是与 HAL service有关 
                                                                                    ---->makeClient      主要是根据 API 版本以及 HAL 版本来选择生成具体的 Client 实例。对于 HAL3 且 CameraAPI2 的情况;实例化了 CameraDeviceClient 类作为 Client（注意此处构造传入了 ICameraDeviceCallbacks，这是连接到 CameraDeviceImpl 的远端回调）;最终，这一 Client 就沿着前面分析下来的路径返回到 CameraDeviceImpl 实例中，被保存到 mRemoteDevice。至此，打开相机流程中，从 App 到 CameraService 的调用逻辑基本上就算走完了。
              /frameworks/av/services/camera/libcameraservice/api2/CameraDeviceClient.cpp       CameraDeviceClient      CameraService 在创建 CameraDeviceClient 之后，会调用它的初始化函数;
              /frameworks/av/services/camera/libcameraservice/common/Camera2ClientBase.cpp      Camera2ClientBase
              /frameworks/av/services/camera/libcameraservice/device3/Camera3Device.cpp         Camera3Device
              --------------------------------------------------------------------------------------------------------
              /frameworks/av/services/camera/libcameraservice/common/CameraProviderManager.cpp  CameraProviderManager

              在 HAL3 中，Camera HAL 的接口转化层（以及流解析层）由 QCamera3HardwareInterface 担当，而接口层与实现层与 HAL1 中基本没什么差别，都是在 mm_camera_interface.c 与 mm_camera.c 中。
    Hal:
              /hardware/interfaces/camera/device/3.2/default/CameraDevice.cpp                   CameraDevice
                                                                                                -->CameraDevice::open
                                                                                                -->CameraDevice::createSession

              /hardware/interfaces/camera/common/1.0/default/CameraModule.cpp                   CameraModule
                                                                                                -->CameraModule::open
                                                                                                ---->mModule->common.methods->open

              /hardware/qcom/camera/qcamera2/QCamera2Factory.cpp                                QCamera2Factory
                                                                                                -->cameraDeviceOpen     首先创建了QCamera3HardwareInterface的实例;调用实例的openCamera方法
                                                                                                ---->hw->openCamera(hw_device)

              /hardware/qcom/camera/qcamera2/hal3/QCamera3HWI.cpp                               QCamera3HardwareInterface
                                                                                                -->QCamera3HardwareInterface::openCamera
                                                                                                ---->rc = openCamera();
                                                                                                ------>QCamera3HardwareInterface::openCamera()
                                                                                                -------->rc = camera_open((uint8_t)mCameraId, &mCameraHandle);

              /hardware/qcom/camera/qcamera2/stack/mm-camera-interface/src/mm_camera_interface.c    camera_open
                                                                                                    -->rc = mm_camera_open(cam_obj);

              /hardware/qcom/camera/qcamera2/stack/mm-camera-interface/src/mm_camera.c          mm_camera_open(mm_camera_obj_t *my_obj)     mm_camera_open 主要工作是填充 my_obj，并且启动、初始化一些线程相关的东西;
                                                                                                -->my_obj->ctrl_fd = open(dev_name, O_RDWR | O_NONBLOCK);       读取设备文件的文件描述符，存到 my_obj->ctrl_fd 中。注意设备文件的路径是 /dev/video0（video 后面的数字表示打开设备的 id），并且在某些打开失败的情况下，会定时重新尝试打开直至成功


