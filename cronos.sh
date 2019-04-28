#!/bin/bash
#
# Cronos Build Script V3.1
# For Exynos7420
# Coded by BlackMesa/AnanJaser1211 @2019
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software

# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Main Dir
CR_DIR=$(pwd)
# Define toolchan path
CR_TC=~/Android/Toolchains/linaro-4.9.4-aarch64-linux/bin/aarch64-linux-gnu-
# Define proper arch and dir for dts files
CR_DTS=arch/arm64/boot/dts
# Define boot.img out dir
CR_OUT=$CR_DIR/Helios/Out
# Presistant A.I.K Location
CR_AIK=$CR_DIR/Helios/A.I.K
# Main Ramdisk Location
CR_RAMDISK=$CR_DIR/Helios/Ramdisk
# Compiled image name and location (Image/zImage)
CR_KERNEL=$CR_DIR/arch/arm64/boot/Image
# Compiled dtb by dtbtool
CR_DTB=$CR_DIR/boot.img-dtb
# Kernel Name and Version
CR_VERSION=V2.5
CR_NAME=HeliosPie_Kernel
# Thread count
CR_JOBS=5
# Target android version and platform (7/n/8/o/9/p)
CR_ANDROID=o
CR_PLATFORM=8.0.0
# Target ARCH
CR_ARCH=arm64
# Current Date
CR_DATE=$(date +%Y%m%d)
# Init build
export CROSS_COMPILE=$CR_TC
# General init
export ANDROID_MAJOR_VERSION=$CR_ANDROID
export PLATFORM_VERSION=$CR_PLATFORM
export $CR_ARCH
##########################################
# Device specific Variables [SM-N920CIGSLK]
CR_DTSFILES_N920C="exynos7420-noblelte_eur_open_00.dtb exynos7420-noblelte_eur_open_01.dtb exynos7420-noblelte_eur_open_02.dtb exynos7420-noblelte_eur_open_03.dtb exynos7420-noblelte_eur_open_04.dtb exynos7420-noblelte_eur_open_05.dtb exynos7420-noblelte_eur_open_06.dtb exynos7420-noblelte_eur_open_08.dtb exynos7420-noblelte_eur_open_09.dtb"
CR_CONFG_N920C=noblelte_defconfig
CR_VARIANT_N920C=N920X
# Device specific Variables [SM-N920P_T_W8]
CR_DTSFILES_N920P_T_W8="exynos7420-noblelte_usa_00.dtb exynos7420-noblelte_usa_01.dtb exynos7420-noblelte_usa_02.dtb exynos7420-noblelte_usa_03.dtb exynos7420-noblelte_usa_04.dtb exynos7420-noblelte_usa_06.dtb exynos7420-noblelte_usa_07.dtb exynos7420-noblelte_usa_08.dtb exynos7420-noblelte_usa_09.dtb"
CR_CONFG_N920P_T_W8=noblelte_US_defconfig
CR_VARIANT_N920P_T_W8=N920P_T_W8
#####################################################

# Script functions

read -p "Clean source (y/n) > " yn
if [ "$yn" = "Y" -o "$yn" = "y" ]; then
     echo "Clean Build"    
     make clean && make mrproper    
     rm -r -f $CR_DTB
     rm -rf $CR_DTS/.*.tmp
     rm -rf $CR_DTS/.*.cmd
     rm -rf $CR_DTS/*.dtb      
else
     echo "Dirty Build"
     rm -r -f $CR_DTB
     rm -rf $CR_DTS/.*.tmp
     rm -rf $CR_DTS/.*.cmd
     rm -rf $CR_DTS/*.dtb          
fi

BUILD_ZIMAGE()
{
	echo "----------------------------------------------"
	echo " "
	echo "Building zImage for $CR_VARIANT"
	export LOCALVERSION=-$CR_NAME-$CR_VERSION-$CR_VARIANT-$CR_DATE
    make  $CR_CONFG 
	make -j$CR_JOBS
	if [ ! -e ./arch/arm64/boot/Image ]; then
	exit 0;
	echo "zImage Failed to Compile"
	echo " Abort "
	fi
	echo " "
	echo "----------------------------------------------"
}
BUILD_DTB()
{
	echo "----------------------------------------------"
	echo " "
	echo "Building DTB for $CR_VARIANT"
	# Use the DTS list provided in the build script.
	# This source does not compile dtbs while doing Image
	make $CR_DTSFILES
	./scripts/dtbTool/dtbTool -o ./boot.img-dtb -d $CR_DTS/ -s 2048
	du -k "./boot.img-dtb" | cut -f1 >dtbsz
	dtbsz=$(head -n 1 dtbsz)
	rm -rf dtbsz
	echo "Combined DTB Size = $dtbsz Kb"
	rm -rf $CR_DTS/.*.tmp
	rm -rf $CR_DTS/.*.cmd
	rm -rf $CR_DTS/*.dtb
	echo " "
	echo "----------------------------------------------"
}
PACK_BOOT_IMG()
{
	echo "----------------------------------------------"
	echo " "
	echo "Building Boot.img for $CR_VARIANT"
	cp -rf $CR_RAMDISK/* $CR_AIK
	# Copy Ramdisk
	cp -rf $CR_RAMDISK/* $CR_AIK
	# Move Compiled kernel and dtb to A.I.K Folder
	mv $CR_KERNEL $CR_AIK/split_img/boot.img-zImage
	mv $CR_DTB $CR_AIK/split_img/boot.img-dtb
	# Create boot.img
	$CR_AIK/repackimg.sh
	# Remove red warning at boot
	echo -n "SEANDROIDENFORCE" » $CR_AIK/image-new.img
    # Calculate Boot.img Size
    du -k "$CR_AIK/image-new.img" | cut -f1 >bootsz
    bootsz=$(head -n 1 bootsz)
    rm -rf bootsz
	# Move boot.img to out dir
	mv $CR_AIK/image-new.img $CR_OUT/$CR_NAME-$CR_VERSION-$CR_DATE-$CR_VARIANT.img
    echo " "
	$CR_AIK/cleanup.sh
}
# Main Menu
clear
echo "----------------------------------------------"
echo "$CR_NAME $CR_VERSION Build Script"
echo "----------------------------------------------"
PS3='Please select your option (1-4): '
menuvar=("SM-N920X" "SM-N920P_T_W8" "Exit")
select menuvar in "${menuvar[@]}"
do
    case $menuvar in
        "SM-N920X")
            clear
            echo "Starting $CR_VARIANT_N920C kernel build..."
            CR_VARIANT=$CR_VARIANT_N920C
            CR_CONFG=$CR_CONFG_N920C
            CR_DTSFILES=$CR_DTSFILES_N920C
            BUILD_ZIMAGE
            BUILD_DTB
            PACK_BOOT_IMG
            echo " "
            echo "----------------------------------------------"
            echo "$CR_VARIANT kernel build finished."
            echo "$CR_VARIANT Ready at $CR_OUT"
            echo "Combined DTB Size = $dtbsz Kb"
            echo "Combined BOOT Size = $bootsz Kb"
            echo "Press Any key to end the script"
            echo "----------------------------------------------"
            read -n1 -r key
            break
            ;;
        "SM-N920P_T_W8")
            clear
            echo "Starting $CR_VARIANT_N920P_T_W8 kernel build..."
            CR_VARIANT=$CR_VARIANT_N920P_T_W8
            CR_CONFG=$CR_CONFG_N920P_T_W8
            CR_DTSFILES=$CR_DTSFILES_N920P_T_W8
            BUILD_ZIMAGE
            BUILD_DTB
            PACK_BOOT_IMG
            echo " "
            echo "----------------------------------------------"
            echo "$CR_VARIANT kernel build finished."
            echo "$CR_VARIANT Ready at $CR_OUT"
            echo "Combined DTB Size = $dtbsz Kb"
            echo "Combined BOOT Size = $bootsz Kb"
            echo "Press Any key to end the script"
            echo "----------------------------------------------"
            read -n1 -r key
            break
            ;;  
    "Exit")
            break
            ;;
        *) echo Invalid option.;;
    esac
done
