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
        media_deivce_register           //register a media device
        media_entity_init
        v4l2_deivce_register            //initialize the v4l2_dev struct
        video_register_device(vdev, VFL_TYPE_GRABBER, -1);          //注册video device，VFL_TYPE_GRABBER表示注册的是视频处理设备，video_nr=-1表示自动分配从设备号,成功会在dev下生成相应的type的节点 
                                                                                            VFL_TYPE_GRABBER: 用于视频输入/输出设备的 videoX
                                                                                            VFL_TYPE_VBI: 用于垂直消隐数据的 vbiX (例如，隐藏式字幕，图文电视)
                                                                                            VFL_TYPE_RADIO: 用于广播调谐器的 radioX
                                                                                            VFL_TYPE_SUBDEV:一个子设备v4l-subdevX 
                                                                                            VFL_TYPE_SDR:Software Defined Radio swradioX
        msm_init_queue  
        cam_ahb_clk_init
    ##msm_probe end
    下面是循环逻辑,这个循环逻辑其实就是在probe各种各样的qcom.camera框架下的外围器件,序列号代表执行次数,当然这个数量是和你dts里面的配置挂钩的.分别包含:
     1                          "msm_cci_probe"             :msm/camera_v2/sensor/cci/msm_cci.c
     2                          "csiphy_probe"              :msm/camera_v2/sensor/csiphy/msm_csiphy.c//dts里面有2个
     3                          "csid_probe"                :msm/camera_v2/sensor/csid/msm_csid.c    //dts里面有3个
     2                          "msm_actuator_i2c_probe或者msm_actuator_platform_probe" :msm/camera_v2/sensor/actuator/msm_actuator.c
     1                          "msm_sensor_init_module"    :msm/camera_v2/sensor/msm_sensor_init.c
     1                          "cpp_probe"                 :msm/camera_v2/pproc/cpp/msm_cpp.c
     1                          "vfe_probe"                 :msm/camera_v2/isp/msm_isp_32.c
     1                          "ispif_probe"               :msm/camera_v2/ispif/msm_ispif_32.c
     1                          "msm_buf_mngr_init"         :msm/camera_v2/msm_buf_mgr/msm_generic_buf_mgr.c

    msm_sd_register        [msm_cci/msm_csiphy/msm_csid/msm_actuator/msm_sensor_init/cpp/vfe/msm_ispif/msm_buf_mngr/]
    中括号里面的设备挨个初始化,再往下的逻辑不是每个subdev都有的
    中括号里面的设备挨个初始化,再往下的逻辑不是每个subdev都有的
    msm_add_sd_in_position
    __msm_sd_register_subdev
            v4l2_device_register_subdev     //initialize the v4l2_subdev struct
            __video_register_device(vdev, VFL_TYPE_SUBDEV, -1, 1,sd->owner);    //注册video_device节点 /dev/v4l-subdevX
    msm_cam_get_v4l2_subdev_fops_ptr
    msm_cam_copy_v4l2_subdev_fops
    msm_sd_notify
    msm_sd_find
    循环结束


---------------------------------------------------------------------------------------
单独看msm_sersor_init的逻辑线
##msm_sensor_init_module start
 msm_sensor_init.c
     msm_sensor_init_module
        v4l2_subdev_init(&s_init->msm_sd.sd, &msm_sensor_init_subdev_ops);
        media_entity_init(&s_init->msm_sd.sd.entity, 0, NULL, 0);
        msm_sd_register
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
        v4l2_fh_open                            ///* create event queue */
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
            media_device_register
            media_entity_init
            v4l2_device_register
            video_register_device
            device_init_wakeup
        v4l2_subdev_init            ///* Create /dev/v4l-subdevX device */
        v4l2_set_subdevdata
        media_entity_init
        msm_sd_register             //msm.c msm_sd_register

 msm.c
    msm_sd_register                 //具体的摄像头sensor, tw9992
        msm_add_sd_in_position
        __msm_sd_register_subdev
            v4l2_device_register_subdev     //initialize the v4l2_subdev struct
            __video_register_device(vdev, VFL_TYPE_SUBDEV, -1, 1,sd->owner);    //注册video_device节点 /dev/v4l-subdevX
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
    .

    kernel/v4l2-core/

