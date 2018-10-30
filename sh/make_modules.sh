#########################################################################
# File Name: make_modules.sh
# Author: maze
# Email: mazema@pateo.com.cn
# Created Time: 2018年02月22日 星期四 10时49分31秒
#########################################################################
#!/bin/bash

source build/envsetup.sh
lunch 
make -C `pwd`/kernel_imx/  ARCH=arm CROSS_COMPILE=`pwd`/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- LOADADDR=0x10008000 KCFLAGS=-mno-android kernelmodules
