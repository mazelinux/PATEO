				　　　　入职指南
注意:下面步骤中所有的yourname 都改成你自己的名字，也就是邮件中的名字,
如果在执行下面步骤的过程中，出现其他的异常情况，百度解决
下面步骤中用的deb包和代码在下面路径，把Ubuntu_Tools文件考到本地
smb://10.10.12.37/share/

０．确保ubuntu版本为16.04.x, x可以为１，２，３[可找It-Support:潘帅,用光碟安装16.04.1,这样可以省去2操作:替换kernel的问题];
	在setting->software & update中把download from改成http://mirrors.aliyun.com/ubuntu
　　找leader或者徐兵发邮件给德兵(debingyang@pateo.com.cn)，让他帮自己开通gerrit账号,添加代码权限。

１．如电脑不能联网，就下面流程装网卡：
	解压压缩包e1000e-3.4.0.2.tar.gz
	cd e1000e-3.4.0.2/src/
	sudo make install
	modprobe e1000e
	sudo modprobe e1000e

２．确保系统kernel版本:
	4.8.0-36-generic，可以用uname -r 系统当前内核版本
	如果不是此版本，用下面命令升级
	sudo apt install linux-*-4.8.0-36-ge*
	内核升级成功后，用这条指令看当前系统下面有那些内核：
	dpkg -l|grep linux-image
	删除其他内核　：
	sudo apt remove linux-*-4.4.0*
	sudo reboot
	查看当前内核是否4.8.0-36-generic，确保当前内核是4.8.0-36-generic。

３．GDebi安装：
	用Gdebi装deb包，解决一些依赖问题
	sudo apt-get install gdebi

４．装搜狗拼音输入法：
	sudo gdebi sogoupinyin_2.2.0.0102_amd64.deb

５．装git工具： 
	sudo apt install git
	配置git：git config --global user.email 和 user.name [xxx@pateo.com.cn;yourname]

６．按德兵回复的邮件中的做，邮件最后会有让你测试之前的所有
　　是否ＯＫ的步骤，暂时也别试，因为需要把下面第７部执行完，才可以测试。

７．装加密的工具:
	进入ultraSec文件夹
	1. sudo ./UltraSec_Client_Install.sh 
	2.重启电脑[必须]
	3.usec   
	  (1 login;2.ip and port)按德兵邮件中设置
	4.如都设置ＯＫ，桌面左上角有个方框里，里面有个向下的标签，点击标签会显示一个S锁，如S锁为
	　红色，就说明加密已ＯＫ，否则就有可能时你设置的问题或者是德兵那边的问题。
	5.上面都ＯＫ了，测试自己能不能拉代码： ssh :ssh -p 29418 yourname@10.10.96.212

8.  装repo工具:
	git clone ssh://yourname@10.10.96.212:29418/tools/git-repo.git tools/repo.git
	sed -i -e 's#USER#yourname#' tools/repo.git/repo
	sudo cp tools/repo.git/repo /usr/local/bin

9.  代码编译环境必须是jdk7,装JDK7:
	sudo add-apt-repository ppa:openjdk-r/ppa 
	sudo apt-get update
	sudo gdebi openjdk-7-jre-headless_7u95-2.6.4-3_amd64.deb
	sudo gdebi openjdk-7-jdk_7u95-2.6.4-3_amd64.deb
	sudo gdebi openjdk-7-dbg_7u95-2.6.4-3_amd64.deb
	sudo apt install openjdk-7-*
	把其他的jdk版本删掉，如下面等版本：
	sudo apt remove openjdk-8-*
	sudo apt remove openjdk-9-*


10.代码路径
	a.一汽车展代码：
	repo init -u ssh://yourname@10.10.96.212:29418/projects/DLS-Auto-Marshmallow/platform/manifest.git -b jupiter_f0307h
	修改manifest:
	//////////////////////////////////
	@@ -301,11 +301,6 @@
	   <project path="frameworks/wilhelm" name="platform/frameworks/wilhelm" groups="pdk-cw-fs,pdk-fs" />
	  
	   <project path="hardware/qghal" name="hardware/qghal" remote="qingos" revision="jupiter" />
	-  <project path="hardware/imx/mx6/audio_sink" name="hardware/bluetooth/ivt_a2dp_sink" remote="qingos" revision="jupiter" />
	-  <project path="hardware/imx/mx6/reverse" name="hardware/reverse" remote="qingos" revision="jupiter_f0307h" />
	-  <project path="hardware/imx/mx6/carplay" name="hardware/carplay" remote="qingos" revision="jupiter" />
	-  <project path="hardware/imx/mx6/bootcontrol" name="hardware/bootcontrol" remote="qingos" revision="jupiter" />
	//////////////////////////////////////
	repo sync
	编译：
	source build/envsetup.sh
	./scripts/build_android.sh f0307h_6qp all

	b.仪表端android系统代码：
	repo init -u ssh://USER@10.10.96.212:29418/projects/DLS-Auto-Marshmallow/platform/manifest.git -b jupiter_android
	修改manifest:
	//////////////////////////////////
	[删除]  <project path="hardware/imx/mx6/audio_sink" name="hardware/bluetooth/ivt_a2dp_sink" remote="qingos" revision="jupiter" />
	//////////////////////////////////////
	repo sync

11.编译源代码
	openjdk1.7安装：
		01. $ sudo add-apt-repository ppa:openjdk-r/ppa   
		02. $ sudo apt-get update   
		03. $ sudo apt-get install openjdk-7-jdk
		查看jdk版本:
			java -version
			javac -version
		显示版本:
			java version "1.7.0_95"

	依赖工具安装:
		sudo apt-get install git-core gnupg flex bison gperf build-essential \

		zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \

		lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache \

		libgl1-mesa-dev libxml2-utils xsltproc unzip m4 lzop mkimage


	源代码修改:
		art/build/Android.common_build.mk

	ART_HOST_CLANG := false
	 ifneq ($(WITHOUT_HOST_CLANG),true)
	  # By default, host builds use clang for better warnings.
	  ART_HOST_CLANG := true
	   endif

	   修改为

	ART_HOST_CLANG := false
	 ifeq ($(WITHOUT_HOST_CLANG),false)
	  # By default, host builds use clang for better warnings.
	  ART_HOST_CLANG := true
	   endif

	编译查看script/build_android.sh
		例如:./script/build_android.sh f0307h all



如在次过程中总结了一些简介的步骤和一些疑难问题的解决方法，可以加在这里，为团队建设出一份力，谢谢！
2018.2.8
BSP:smartxu@pateo.com.cn
2018.2.11
第一次修改


