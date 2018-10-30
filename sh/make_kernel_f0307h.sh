#!/bin/bash

CPUS=$(( $(cat /proc/cpuinfo | grep processor | tail -n 1 | cut -d":" -f 2) + 1))

if [ -z ${1} ]; then
	echo "ERROR: Need to specify parameter, e.g.:"
	echo "${0} config"
	echo "${0} n140"
	echo "${0} v3"
	echo "${0} carplay"
	echo "${0} f0307h"
	exit 0
fi

if [ $1 == "v3" ]; then
dtsplat="imx6q:imx6q-e0001h-v3.dtb"
else
dtsplat="imx6q:imx6qp-f0307h.dtb"
#dtsplat="imx6q:imx6q-f0307h.dtb"
fi
#kernel config
function check_exit()
{
    if [ $? != 0 ];then
    echo -e "something nasty happened"
    exit $?
    fi
}

if  [ $1 == "n140" ]; then
make -C kernel_imx -j$CPUS imx_v7_e0001h_android_n140_defconfig ARCH=arm CROSS_COMPILE=`pwd`/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- LOADADDR=0x10008000 KCFLAGS=-mno-android
fi

if  [ $1 == "config" ]; then
make -C kernel_imx -j$CPUS imx_v7_e0001h_android_defconfig ARCH=arm CROSS_COMPILE=`pwd`/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- LOADADDR=0x10008000 KCFLAGS=-mno-android
fi

if  [ $1 == "v3" ]; then
make -C kernel_imx -j$CPUS imx_v7_e0001h_v3_android_defconfig  ARCH=arm CROSS_COMPILE=`pwd`/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- LOADADDR=0x10008000 KCFLAGS=-mno-android
fi

if  [ $1 == "carplay" ]; then
make -C kernel_imx -j$CPUS imx_v7_e0001h_android_carplay_defconfig  ARCH=arm CROSS_COMPILE=`pwd`/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- LOADADDR=0x10008000 KCFLAGS=-mno-android
fi

if  [ $1 == "f0307h" ]; then
make -C kernel_imx -j$CPUS imx_v7_x37_android_defconfig  ARCH=arm CROSS_COMPILE=`pwd`/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- LOADADDR=0x10008000 KCFLAGS=-mno-android
check_exit
fi

make -C kernel_imx -j$CPUS uImage ARCH=arm CROSS_COMPILE=`pwd`/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- LOADADDR=0x10008000 KCFLAGS=-mno-android
check_exit


make -C kernel_imx -j$CPUS modules ARCH=arm CROSS_COMPILE=`pwd`/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- LOADADDR=0x10008000 KCFLAGS=-mno-android
check_exit

install -D kernel_imx/arch/arm/boot/zImage out/target/product/f0307h/kernel
check_exit

#compile dtb
make -C kernel_imx dtbs ARCH=arm CROSS_COMPILE=`pwd`/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- LOADADDR=0x10008000 KCFLAGS=-mno-android
check_exit

DTS_PLATFORM=`echo $dtsplat | cut -d':' -f1`
DTS_BOARD=`echo $dtsplat | cut -d':' -f2`
install -D kernel_imx/arch/arm/boot/dts/$DTS_BOARD out/target/product/f0307h/$DTS_BOARD;
BOOT_IMAGE_BOARD=out/target/product/f0307h/boot-$DTS_PLATFORM.img;

#make image-adb
out/host/linux-x86/bin/mkbootimg  --kernel out/target/product/f0307h/kernel --ramdisk out/target/product/f0307h/ramdisk.img --cmdline "console=ttymxc0,115200 init=/init video=mxcfb0:dev=ldb,bpp=32 video=mxcfb1:off video=mxcfb2:off video=mxcfb3:off vmalloc=256M androidboot.console=ttymxc0 consoleblank=0 androidboot.hardware=freescale cma=384M" --base 0x14000000 --second out/target/product/f0307h/$DTS_BOARD  --output out/target/product/f0307h/boot.img
check_exit

out/host/linux-x86/bin/boot_signer /boot out/target/product/f0307h/boot.img build/target/product/security/verity.pk8 build/target/product/security/verity.x509.pem out/target/product/f0307h/boot-imx6qp_adb.img
check_exit
