#########################################################################
# File Name: make_f0307h.sh
# Author: maze
# Email: mazema@pateo.com.cn
# Created Time: 2018年03月16日 星期五 13时31分01秒
#########################################################################
#!/bin/bash -x
BUILD_CHOICE=${1}
ANDROID_BUILD_TYPE=${2}
VERSION_TYPE=${3}
BOARD=f0307h

#######################################
# Set environment
#######################################
ROOT_DIR=$(pwd)
OUT_DIR=${ROOT_DIR}/out/target/product/f0307h

function check_exit()
{
    if [ $? != 0 ]; then
    echo -e "something nasty happened"
    exit $?
    fi
}


if [ -z ${BUILD_CHOICE} ]; then
	echo "ERROR: Need to specify img, e.g.:"
	echo "${0} bootloader"
	echo "${0} ramdisk"
	echo "${0} kernel2g"
	echo "${0} kernel4g"
	echo "${0} android"
	echo "${0} all"
	echo "If you want build boot.img ;make sure you have ramdisk.img ,mkbootimg ,boot_signer !!!"
	exit 0
fi

if [ -z ${ANDROID_BUILD_TYPE} ]; then
	echo "ERROR: Need to specify type, e.g.:"
	echo "${0} ${1} user"
	echo "${0} ${1} eng"
    exit 0
fi

# Number of CPUs used to build [U-Boot+kernel] and [Android]
# Android can have issues building using several CPUs
CPUS=$(( $(cat /proc/cpuinfo | grep processor | tail -n 1 | cut -d":" -f 2) + 1))
CPUS=`echo "${CPUS}*0.8"|bc|awk -F. '{print $1}'`
CPUS_ANDROID=$(( $(cat /proc/cpuinfo | grep processor | tail -n 1 | cut -d":" -f 2) + 1))
CPUS_ANDROID=`echo "${CPUS_ANDROID}*0.8"|bc|awk -F. '{print $1}'`

function buildkernel4g()
{

dtsplat="imx6q:imx6qp-f0307h.dtb"
make -C kernel_imx -j$CPUS imx_v7_x37_4g_android_defconfig  ARCH=arm CROSS_COMPILE=`pwd`/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- LOADADDR=0x10008000 KCFLAGS=-mno-android
check_exit

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

out/host/linux-x86/bin/boot_signer /boot out/target/product/f0307h/boot.img build/target/product/security/verity.pk8 build/target/product/security/verity.x509.pem out/target/product/f0307h/boot-4g_adb.img
check_exit

}

function buildkernel()
{

dtsplat="imx6q:imx6qp-f0307h.dtb"
make -C kernel_imx -j$CPUS imx_v7_x37_android_defconfig  ARCH=arm CROSS_COMPILE=`pwd`/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- LOADADDR=0x10008000 KCFLAGS=-mno-android
check_exit

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
out/host/linux-x86/bin/boot_signer /boot out/target/product/f0307h/boot.img build/target/product/security/verity.pk8 build/target/product/security/verity.x509.pem out/target/product/f0307h/boot.img
check_exit

}

function buildkernel_only()
{

dtsplat="imx6q:imx6qp-f0307h.dtb"
make -C kernel_imx -j$CPUS imx_v7_x37_android_defconfig  ARCH=arm CROSS_COMPILE=`pwd`/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- LOADADDR=0x10008000 KCFLAGS=-mno-android
check_exit

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

}


case "$BUILD_CHOICE" in
	"all")
		BUILD_UBOOT=1
        BUILD_KERNEL_OLD=1
		BUILD_ANDROID=1
		BUILD_ALLPACKAGE=1
		;;

	"bootloader")
		BUILD_UBOOT=1
		;;

    "ramdisk")
        BUILD_RAMDISK=1
        ;;

	"kernel2g")
        BUILD_RAMDISK=1
		BUILD_KERNEL2G=1
		;;

	"kernel4g")
        BUILD_RAMDISK=1
		BUILD_KERNEL4G=1
		;;

	"android")
		BUILD_ANDROID=1
		;;

	"recovery")
		BUILD_RECOVERY=1
		;;
	
	"allpackage")
		BUILD_ALLPACKAGE=1
		;;

	*)
		echo "Error must choose a built target, e.g.:"
	    echo "${0} bootloader"
	    echo "${0} kernel2g"
	    echo "${0} kernel4g"
	    echo "${0} android"
	    echo "${0} all"
		exit 1
		;;
esac

#######################################
# Build
#######################################
cd ${ROOT_DIR}
source build/envsetup.sh > /dev/null
lunch f0307h-${ANDROID_BUILD_TYPE}

if [ "${BUILD_UBOOT}" > "0" ]; then
	rm -f ${ROOT_DIR}/out/target/product/${BOARD}/u-boot.bin
	make bootloader -j${CPUS} 2>&1 | tee build_${BOARD}_uboot.log
fi

if [ "${BUILD_RAMDISK}" > "0" ]; then
	make ramdisk -j${CPUS}  2>&1 | tee build_${BOARD}_ramdisk.log
fi

if [ "${BUILD_KERNEL_OLD}" > "0" ]; then
	make kernelimage -j${CPUS}  2>&1 | tee build_${BOARD}_kernel.log
fi

if [ "${BUILD_KERNEL2G}" > "0" ]; then
#	make kernelimage -j${CPUS}  2>&1 | tee build_${BOARD}_android.log
buildkernel -j${CPUS} 2>&1 |tee build_${BOARD}_kernel.log
fi

if [ "${BUILD_KERNEL4G}" > "0" ]; then
buildkernel4g -j${CPUS}  2>&1 | tee build_${BOARD}_android.log
fi

if [ "${BUILD_ANDROID}" > "0" ]; then
	make update-api
	make PRODUCT-${BOARD}-${ANDROID_BUILD_TYPE} -j${CPUS_ANDROID} 2>&1 | tee build_${BOARD}_android.log
fi

if [ "${BUILD_OTAPACKAGE}" > "0" ]; then
	make otapackage -j${CPUS_ANDROID} 2>&1 | tee build_${BOARD}_android.log
	make mcupackage -j${CPUS_ANDROID} 2>&1 | tee build_${BOARD}_android.log
fi

if [ "${BUILD_RECOVERY}" > "0" ]; then
	make recoveryimage -j${CPUS_ANDROID} 2>&1 | tee build_${BOARD}_${BUILD_CHOICE}.log
fi

if [ "${BUILD_FACTORYPACKAGE}" > "0" ]; then
	make factorypackage -j${CPUS_ANDROID} BUILD_VERSION_TYPE=${VERSION_TYPE} 2>&1 | tee build_${BOARD}_${BUILD_CHOICE}.log
fi

if [ "${BUILD_RESOURCEIMAGE}" > "0" ]; then
	make resourceimage -j${CPUS_ANDROID} 2>&1 | tee build_${BOARD}_${BUILD_CHOICE}.log
fi

if [ "${BUILD_ALLPACKAGE}" > "0" ]; then
	make allpackage -j${CPUS_ANDROID} BUILD_VERSION_TYPE=${VERSION_TYPE} 2>&1 | tee build_${BOARD}_${BUILD_CHOICE}.log
fi

