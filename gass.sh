#!/bin/bash
kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
anykernel=$HOME/anykernel
builddir="${kernel_dir}/build"
ZIMAGE=$kernel_dir/out/arch/arm64/boot/Image.gz-dtb
kernel_name="Fussion_Kernel4.19_Mido"
zip_name="$kernel_name-$(date +"%d%m%Y-%H%M").zip"
TC_DIR=$HOME/tc/
CLANG_DIR=$TC_DIR/clang-r450784d
export CONFIG_FILE="vendor/mido_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST=17
export KBUILD_BUILD_USER=areal28
export PATH="$CLANG_DIR/bin:$PATH"

if ! [ -d "$TC_DIR" ]; then

    echo "Toolchain not found! Cloning to $TC_DIR..."
    if ! git clone -q --depth=1 --single-branch https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 -b android13-release $TC_DIR; then
        echo "Cloning failed! Aborting..."
        exit 1
    fi
fi

# Colors
NC='\033[0m'
RED='\033[0;31m'
LRD='\033[1;31m'
LGR='\033[1;32m'

mrproper
make oldconfig
make_defconfig()
{
    START=$(date +"%s")
    echo -e ${LGR} "########### Generating Defconfig ############${NC}"
    make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE} -j$(nproc --all)
}
compile()
{
    cd ${kernel_dir}
    echo -e ${LGR} "######### Compiling kernel #########${NC}"
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
	                      CONFIG_NO_ERROR_ON_MISMATCH=y
}
completion()
{
    cd ${objdir}
    COMPILED_IMAGE=arch/arm64/boot/Image.gz-dtb
    if [[ -f ${COMPILED_IMAGE} ]]; then

        git clone -q https://github.com/NRanjan-17/AnyKernel3 -b mido $anykernel

        mv -f $ZIMAGE $anykernel
        
        cd $anykernel
        find . -name "*.zip" -type f
        find . -name "*.zip" -type f -delete
        zip -r AnyKernel.zip *
        mv AnyKernel.zip $zip_name
        mv $anykernel/$zip_name $HOME/$zip_name
        rm -rf $anykernel
        END=$(date +"%s")
        DIFF=$(($END - $START))
        curl --upload-file $HOME/$zip_name https://free.keep.sh; echo
        rm $HOME/$zip_name
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
}
make_defconfig
compile
completion
cd ${kernel_dir}
