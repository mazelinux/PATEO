#########################################################################
# File Name: make_imx8qm.sh
# Author: maze
# Email: mazema@pateo.com.cn
# Created Time: 2018年05月24日 星期四 15时06分48秒
#########################################################################
#!/bin/bash -x
BUILD_CHOICE=${1}
ANDROID_BUILD_TYPE=${2}
BOARD=vinson

#######################################
# Set environment
#######################################
ROOT_DIR=$(pwd)
MY_ANDROID=$(pwd)
OUT_DIR=${ROOT_DIR}/out/target/product/${BOARD}

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
	echo "${0} bootimage"
	echo "${0} android"
	echo "${0} all"
	exit 0
fi

if [ -z ${ANDROID_BUILD_TYPE} ]; then
	echo "ERROR: Need to specify type, e.g.:"
	echo "${0} ${1} userdebug"
    exit 0
fi

# Number of CPUs used to build [U-Boot+kernel] and [Android]
# Android can have issues building using several CPUs
CPUS=$(( $(cat /proc/cpuinfo | grep processor | tail -n 1 | cut -d":" -f 2) + 1))
CPUS=`echo "${CPUS}*0.8"|bc|awk -F. '{print $1}'`
CPUS_ANDROID=$(( $(cat /proc/cpuinfo | grep processor | tail -n 1 | cut -d":" -f 2) + 1))
CPUS_ANDROID=`echo "${CPUS_ANDROID}*0.8"|bc|awk -F. '{print $1}'`

case "$BUILD_CHOICE" in
	"all")
		BUILD_UBOOT=1
        BUILD_BOOT=1
		BUILD_ANDROID=1
		BUILD_ALLPACKAGE=1
		;;

	"bootloader")
		BUILD_UBOOT=1
		;;

	"bootimage")
        BUILD_RAMDISK=1
		BUILD_KERNEL=1
        BUILD_BOOT=1
		;;

	"android")
		BUILD_ANDROID=1
		;;

	"recovery")
		BUILD_RECOVERY=1
		;;

	*)
		echo "Error must choose a built target, e.g.:"
	    echo "${0} bootloader"
	    echo "${0} bootimage"
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
lunch vinson-${ANDROID_BUILD_TYPE}

if [ "${BUILD_UBOOT}" > "0" ]; then
#	rm -f ${ROOT_DIR}/out/target/product/${BOARD}/u-boot.bin
#	make bootloader -j${CPUS} 2>&1 | tee build_${BOARD}_uboot.log
    cd ${MY_ANDROID}/vendor/nxp-opensource/uboot-imx
    export CROSS_COMPILE=${MY_ANDROID}/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
    make distclean
    make mx8qm_lpddr4_vinson_android_defconfig
    make
    cp ${MY_ANDROID}/out/target/product/vinson/obj/BOOTLOADER_OBJ/u-boot.bin ${MY_ANDROID}/vendor/nxp-opensource/imx-mkimage/iMX8QM/u-boot.bin
    cp ${MY_ANDROID}/vendor/nxp/fsl-proprietary/uboot-firmware/imx8q/mx8qm-scfw-tcm.bin ${MY_ANDROID}/vendor/nxp-opensource/imx-mkimage/iMX8QM/scfw_tcm.bin
#    cp ${MY_ANDROID}/vendor/nxp/fsl-proprietary/uboot-firmware/imx8qm_dcd.cfg.tmp ${MY_ANDROID}/vendor/nxp-opensource/imx-mkimage/iMX8QM/.
    cp ${MY_ANDROID}/vendor/nxp//fsl-proprietary/uboot-firmware/imx8q/bl31-imx8qm.bin ${MY_ANDROID}/vendor/nxp-opensource/imx-mkimage/iMX8QM/.
    cd ${MY_ANDROID}/vendor/nxp-opensource/imx-mkimage/ 
    make  clean
    make  SOC=iMX8QM flash
    cp ./iMX8QM/flash.bin ${MY_ANDROID}/out/target/product/vinson/u-boot-imx8qm.imx
fi

if [ "${BUILD_RAMDISK}" > "0" ]; then
	make ramdisk -j${CPUS}  2>&1 | tee build_${BOARD}_ramdisk.log
fi

if [ "${BUILD_KERNEL}" > "0" ]; then
#	make kernelimage -j${CPUS}  2>&1 | tee build_${BOARD}_kernel.log
    cd ${MY_ANDROID}/vendor/nxp-opensource/kernel_imx
    echo $ARCH && echo $CROSS_COMPILE
    export ARCH=arm64
    export CROSS_COMPILE=${MY_ANDROID}/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
#    make android_defconfig
    make imx8qm_vinson_android_defconfig
    make KCFLAGS=-mno-android
fi

if [ "${BUILD_BOOT}" > "0" ]; then
#	make kernelimage -j${CPUS}  2>&1 | tee build_${BOARD}_android.log
#buildkernel -j${CPUS} 2>&1 |tee build_${BOARD}_kernel.log
    cd ${MY_ANDROID}
	make bootimage -j${CPUS}  2>&1 | tee build_${BOARD}_bootimage.log
fi


if [ "${BUILD_ANDROID}" > "0" ]; then
    cd ${MY_ANDROID}
	make update-api
	make -j${CPUS_ANDROID} 2>&1 | tee build_${BOARD}_android.log
fi

