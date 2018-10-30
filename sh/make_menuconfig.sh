#########################################################################
# File Name: make_menuconfig.sh
# Author: maze
# Email: mazema@pateo.com.cn
# Created Time: 2018年02月13日 星期二 10时14分32秒
#########################################################################
#!/bin/bash -x

MEM=${1}

if [ -z ${MEM} ]; then
    echo "${0} 1  :imx_v7_x37_android_defconfig"
    echo "${0} 2  :imx_v7_x37_android_carplay_defconfig"
    echo "${0} 3  :imx_v7_x37_4g_android_defconfig"
    echo "${0} 4  :imx_v7_x37_4g_android_carplay_defconfig"
    echo "${0} 5  :imx8qm_vison_android_defconfig"
    exit 0
fi

function check_exit()
{
    if [ $? != 0 ];then
    echo -e "something nasty happened"
    exit $?
    fi
}

source build/envsetup.sh
lunch 

KERNEL_DEFCONFIG=$(get_build_var TARGET_KERNEL_DEFCONF)

if [ "${MEM}" -gt "4" ]; then
cd vendor/nxp-opensource/kernel_imx
check_exit
rm .config
else
cd kernel_imx
check_exit
rm .config
fi

if [ "${MEM}" -gt "4" ]; then

echo -e "choice ${MEM}"
echo -e "make imx8qm_vinson_android_defconfig"
make imx8qm_vinson_android_defconfig ARCH=arm64
elif [ "${MEM}" -gt "3" ]; then

echo -e "choice ${MEM}"
echo -e "make imx_v7_x37_4g_android_carplay_defconfig"
make imx_v7_x37_4g_android_carplay_defconfig ARCH=arm
elif [ "${MEM}" -gt "2" ]; then

echo -e "choice ${MEM}"
echo -e "make imx_v7_x37_4g_android_defconfig"
make imx_v7_x37_4g_android_defconfig ARCH=arm
elif [ "${MEM}" -gt "1" ]; then

echo -e "choice ${MEM}"
echo -e "make imx_v7_x37_android_carplay_defconfig"
make imx_v7_x37_android_carplay_defconfig ARCH=arm
elif [ "${MEM}" -gt "0" ]; then

echo -e "choice ${MEM}"
echo -e "make imx_v7_x37_android_defconfig"
make imx_v7_x37_android_defconfig ARCH=arm
else

echo -e "make with no defconfig"
fi

if [ "${MEM}" -gt "4" ]; then
make menuconfig ARCH=arm64
cp .config arch/arm64/configs/${KERNEL_DEFCONFIG}
else
make menuconfig ARCH=arm
cp .config arch/arm64/configs/${KERNEL_DEFCONFIG}
fi
check_exit
