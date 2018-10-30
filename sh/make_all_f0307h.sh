#########################################################################
# File Name: make_all_f0307h.sh
# Author: maze
# Email: mazema@pateo.com.cn
# Created Time: 2018年03月02日 星期五 20时04分57秒
#########################################################################
#!/bin/bash
BUILD_TYPE=${1}
if [ -z ${BUILD_TYPE} ]; then
    BUILD_TYPE=eng
fi

function check_exit()
{
    if [ $? != 0 ];then
    echo -e "something nasty happened"
    exit $?
    fi
}

./scripts/build_android.sh f0307h all ${BUILD_TYPE}
check_exit
./scripts/build_android.sh f0307h allpackage ${BUILD_TYPE}
check_exit

