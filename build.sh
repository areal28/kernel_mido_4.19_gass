#!/bin/bash
#
# Copyright (C) 2020 Fox kernel project
#
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
#

# Setup colour for the script
yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
green='\e[0;32m'

# Deleting out "kernel complied" and zip "anykernel" from an old compilation
echo -e "$green << cleanup >> \n $white"

rm -rf out
rm -rf zip
rm -rf error.log

echo -e "$green << setup dirs >> \n $white"

# With that setup , the script will set dirs and few important thinks

MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi
DEVICE="Redmi Note 4/4X"
CODENAME="mido"
KERNEL_NAME="FussionKernel"
DEFCONFIG="vendor/mido_defconfig"
AnyKernel="https://github.com/Hunter-commits/anykernel.git"
AnyKernelbranch="master"
HOSST="areal28's Buildbot"
USEER="areal28"
TOOLCHAIN="clang"
if [ "$TOOLCHAIN" == gcc ]; then
	if [ ! -d "$HOME/gcc64" ] && [ ! -d "$HOME/gcc32" ]
	then
		echo -e "$green << cloning gcc from arter >> \n $white"
		git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 "$HOME"/gcc64
		git clone --depth=1 https://github.com/mvaisakh/gcc-arm "$HOME"/gcc32
	fi
	export PATH="$HOME/gcc64/bin:$HOME/gcc32/bin:$PATH"
	export STRIP="$HOME/gcc64/aarch64-elf/bin/strip"
	export KBUILD_COMPILER_STRING=$("$HOME"/gcc64/bin/aarch64-elf-gcc --version | head -n 1)
elif [ "$TOOLCHAIN" == clang ]; then
	if [ ! -d "$HOME/proton_clang" ]
	then
		echo -e "$green << cloning proton clang >> \n $white"
		git clone --depth=1 https://github.com/kdrag0n/proton-clang.git "$HOME"/proton_clang
	fi
	export PATH="$HOME/proton_clang/bin:$PATH"
	export STRIP="$HOME/proton_clang/aarch64-linux-gnu/bin/strip"
	export KBUILD_COMPILER_STRING=$("$HOME"/proton_clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
fi

# Setup build process

build_kernel() {
Start=$(date +"%s")

if [ "$TOOLCHAIN" == clang  ]; then
	echo clang
	make -j$(nproc --all) O=out \
                              ARCH=arm64 \
	                      CC="ccache clang" \
	                      AR=llvm-ar \
	                      NM=llvm-nm \
	                      STRIP=llvm-strip \
	                      OBJCOPY=llvm-objcopy \
	                      OBJDUMP=llvm-objdump \
	                      OBJSIZE=llvm-size \
	                      READELF=llvm-readelf \
	                      HOSTCC=clang \
	                      HOSTCXX=clang++ \
	                      HOSTAR=llvm-ar \
	                      CROSS_COMPILE=aarch64-linux-gnu- \
	                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
	                      CONFIG_DEBUG_SECTION_MISMATCH=y \
	                      CONFIG_NO_ERROR_ON_MISMATCH=y   2>&1 | tee error.log
elif [ "$TOOLCHAIN" == gcc  ]; then
	echo gcc
	make -j$(nproc --all) O=out \
			      ARCH=arm64 \
			      CROSS_COMPILE=aarch64-elf- \
			      CROSS_COMPILE_ARM32=arm-eabi- 2>&1 | tee error.log
fi

End=$(date +"%s")
Diff=$(($End - $Start))
}

export IMG="$MY_DIR"/out/arch/arm64/boot/Image.gz-dtb

# Let's start

echo -e "$green << doing pre-compilation process >> \n $white"
export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64

export KBUILD_BUILD_HOST="$HOSST"
export KBUILD_BUILD_USER="$USEER"

mkdir -p out

make O=out clean && make O=out mrproper
make "$DEFCONFIG" O=out

echo -e "$yellow << compiling the kernel >> \n $white"

build_kernel || error=true

DATE=$(date +"%Y%m%d-%H%M%S")
KERVER=$(make kernelversion)

        if [ -f "$IMG" ]; then                                 
       
        curl --upload-file $IMG https://free.keep.sh; echo
        
        echo -e ${LGR} "############################################"
        echo -e ${LGR} "############# OkThisIsEpic!  ##############"
        echo -e ${LGR} "############################################${NC}"
        exit 0
    else
        echo -e ${RED} "############################################"
        echo -e ${RED} "##         This Is Not Epic :'(           ##"
        echo -e ${RED} "############################################${NC}"
        exit 1
    fi      
