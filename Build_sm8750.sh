#!/bin/bash

# 颜色定义
info(){
tput Setaf3
回声"[INFO]$1"
tput sgr0
}

误差(){
tput Setaf1
回声"[错误]$1"
tput sgr0
出口1
}

# 参数设置
enable_KPM=正确
enable_LZ4KD=正确

# 机型选择
信息"请选择要编译的机型："
信息"1.一加ACE5Pro"
信息"2. 一加 13"
信息"3.一加13T"
信息"4.一加pad2Pro"
读"输入选择-p"输入选择[4]: "："设备选择(_C)

案例$device_choice在……内
    1)
        device_NAME="oneplus_ace5_pro"
        repo_MANIFEST="JiuGeFaCai_oneplus_ace5_pro_v.XML"
        kernel_TIME="星期二12月17日23:36:49UTC2024"
        kernel_SUFFIX="-android15-8-g013ec21bba94-abogki383916444-4k"
        ;;
    2)
device_NAME="oneplus_13"
repo_MANIFEST="JiuGeFaCai_oneplus_13_v.XML"
kernel_TIME="星期二Dec1723:36:49UTC2024"
kernel_SUFFIX="-android15-8-g013ec21bba94-abogki383916444-4k"
        ;;
    3)
device_NAME="oneplus_13t"
repo_MANIFEST="oneplus_13t.xml"
kernel_TIME="FriApr2501:56:53UTC2025"
kernel_SUFFIX="-android15-8-gba3bcfd39307-abogki413159095-4k"
        ;;
    4)
device_NAME="oneplus_pad_2_pro"
repo_MANIFEST="oneplus_pad_2_pro.xml"
kernel_TIME="星期三Dec1119:16:38UTC2024"
kernel_SUFFIX="-android15-8-g0261dbe3cf7e-ab12786384-4k"
        ;;
    *)
错误“”无效的选择，请输入1-3之间的数字"
        ;;
ESAC

# 自定义补丁

read-p"输入内核名称修改(可改中文和emoji回车默认)："input_suffix
[-n"$input_suffix"]&&KERNEL_SUFFIX="$input_suffix"

读取-p"输入内核构建日期更改(回车默认为原厂)："input_time
[-n"$input_time"]&&KERNEL_TIME="$input_time"

读取-p"读取-p"是否启用kpm？(回车默认开启)[y/N]："KPM"kpm
[[ "$kpm"=~[nN]]&&ENABLE_KPM=false

读取-p"是否启用lz4+zstd？(回车默认开启)[y/N]："lz4
[[ "$lz4"=~[nN]]&&ENABLE_LZ4KD=false

#环境变量-按机型区分ccache目录
导出ccache_COMPILERCHECK="%编译器%-倾卸机；%编译器%-dumpversion"
导出ccache_NOHASHDIR="正确"
导出ccache_hardlink="正确"
导出ccache_DIR="$HOME/.ccache_${DEVICE_NAME}"  # 改为按机型区分
导出ccache_MAXSIZE="8g"

#ccache初始化标志文件也按机型区分
ccache_INIT_FLAG="$CCACHE_DIR/.ccache_initialized"

#初始化ccache（仅第一次）
如果命令-v ccache>/dev/null2>&1；，则
如果[！-f"$CCACHE_INIT_FLAG"]；然后
信息"第一次为${DEVICE_NAME}初始化ccache..."
mkdir-p"$CCACHE_DIR"||错误"无法创建ccache目录"
ccache-M"$CCACHE_MAXSIZE"
触摸"$CCACHE_INIT_FLAG"
其他
信息"ccache(${DEVICE_NAME}) 已初始化，跳过..."
Fi
其他
信息"信息"未安装ccache，跳过初始化""
Fi

# 工作目录 - 按机型区分
workspace="$HOMEworkspace="$HOME/kernel_${DEVICE_NAME}"${DEVICE_NAME}"
mkdir-p"$Workspace"||错误"mkdir-p"$Workspace"||错误"无法创建工作目录""
CD"$Workspace"||错误"CD"$Workspace"||错误"无法进入工作目录""

# 检查并安装依赖
信息"信息"检查并安装依赖...""
deps=(使python3git curlccacheflex bison libssl-dev libelf-dev bc zip)
missing_DEPS=()

用于“”中的包装${DEPS[@]}"用于“”中的包装${DEPS[@]}"；do
如果！dpkg-s"$pkg">/dev/null2>&1；然后"$pkg">/dev/null2>&1；然后
missing_DEPS+=("$pkg")"$pkg")
Fi
已完成

如果[${#MISSING_DEPS[@]}-eq0]；然后${#MISSING_DEPS[@]}-eq0]；然后
信息"所有依赖已安装，跳过安装。""所有依赖已安装，跳过安装。"
其他
信息"缺少依赖：${MISSING_DEPS[*]}，正在安装...""缺少依赖：${MISSING_DEPS[*]}，正在安装..."
sudo apt更新||错误"系统更新失败"
    sudo apt install -y "${MISSING_DEPS[@]}"||错误"依赖安装失败"
Fi

# 配置 Git（仅在未配置时）
信息"检查 Git 配置..."

GIT_NAME=$(git config --global user.name || echo "")
GIT_EMAIL=$(git config --global user.email || echo "")

if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL"]；然后
信息"Git 未配置，正在设置..."
    git config --global user.name "Q1道峪"
    git config --global user.email "sucisama2888@gmail.com"
其他
信息"Git 已配置："
Fi

# 安装repo工具（仅首次）
if ! command -v repo >/dev/null 2>&1; then
信息"安装repo工具..."
    curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo > ~/repo || error "repo下载失败"
    chmod a+x ~/repo
    sudo mv ~/repo /usr/local/bin/repo || error "repo安装失败"
其他
    info "repo工具已安装，跳过安装"
Fi

# ==================== 源码管理 ====================

# 创建源码目录
KERNEL_WORKSPACE="$WORKSPACE/kernel_workspace"

mkdir -p "$KERNEL_WORKSPACE" || error "无法创建kernel_workspace目录"

cd "$KERNEL_WORKSPACE" || error "无法进入kernel_workspace目录"

# 初始化源码
info "初始化repo并同步源码..."
repo init -u https://github.com/OnePlusOSS/kernel_manifest.git -b refs/heads/oneplus/sm8750 -m "$REPO_MANIFEST" --depth=1 || error "repo初始化失败"
repo --trace sync -c -j$(nproc --all) --no-tags || error "repo同步失败"

# ==================== 核心构建步骤 ====================

# 清理保护导出
info "清理保护导出文件..."
rm -f kernel_platform/common/android/abi_gki_protected_exports_*
rm -f kernel_platform/msm-kernel/android/abi_gki_protected_exports_*

# 设置SukiSU
info "设置SukiSU..."
cd kernel_platform || error "进入kernel_platform失败"
curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/susfs-main/kernel/setup.sh" | bash -s susfs-main
cd KernelSU || error "进入KernelSU目录失败"
KSU_VERSION=$(expr $(/usr/bin/git rev-list --count main) "+" 10700)
export KSU_VERSION=$KSU_VERSION
sed -i "s/DKSU_VERSION=12800/DKSU_VERSION=${KSU_VERSION}/" kernel/Makefile || error "修改KernelSU版本失败"
info "$KSU_VERSION"

# 设置susfs
info "设置susfs..."
cd "$KERNEL_WORKSPACE" || error "返回工作目录失败"
git clone -q https://gitlab.com/simonpunk/susfs4ksu.git -b gki-android15-6.6 || info "susfs4ksu已存在或克隆失败"
git clone -q https://github.com/SukiSU-Ultra/SukiSU_patch.git || info "SukiSU_patch已存在或克隆失败"
cd kernel_platform || error "进入kernel_platform失败"
cp ../susfs4ksu/kernel_patches/50_add_susfs_in_gki-android15-6.6.patch ./common/
cp ../susfs4ksu/kernel_patches/fs/* ./common/fs/
cp ../susfs4ksu/kernel_patches/include/linux/* ./common/include/linux/

cd $KERNEL_WORKSPACE/kernel_platform/common || { echo "进入common目录失败"; exit 1; }


# 判断当前编译机型是否为一加13t
if [ "$DEVICE_NAME" = "oneplus_13t" ]; then
    info "当前编译机型为一加13T, 跳过patch补丁应用"
else
    info "DEVICE_NAME is $DEVICE_NAME, 正在应用patch补丁..."
    
    # 应用补丁

    sed -i 's/-32,12 +32,38/-32,11 +32,37/g' 50_add_susfs_in_gki-android15-6.6.patch
    sed -i '/#include <trace\/hooks\/fs.h>/d' 50_add_susfs_in_gki-android15-6.6.patch
fi

patch -p1 < 50_add_susfs_in_gki-android15-6.6.patch || info "SUSFS补丁应用可能有警告"
cp "$KERNEL_WORKSPACE/SukiSU_patch/hooks/syscall_hooks.patch" ./ || error "复制syscall_hooks.patch失败"
patch -p1 -F 3 < syscall_hooks.patch || info "syscall_hooks补丁应用可能有警告"

# 应用HMBird GKI补丁
apply_hmbird_patch() {
    info "开始应用HMBird GKI补丁..."
    
    # 进入目录（带错误检查）
    cd drivers || error "进入drivers目录失败"
    
    # 设置补丁URL（移除local关键字）
    patch_url="https://raw.githubusercontent.com/showdo/build_oneplus_sm8750/main/hmbird_patch.c"
    
    info "从GitHub下载补丁文件..."
    if ! curl -sSLo hmbird_patch.c "$patch_url"; then
        error "补丁下载失败，请检查网络或URL: $patch_url"
    fi

    # 验证文件内容
    if ! grep -q "MODULE_DESCRIPTION" hmbird_patch.c; then
        error "下载的文件不完整或格式不正确"
    fi

    # 更新Makefile
    info "更新Makefile配置..."
    if ! grep -q "hmbird_patch.o" Makefile; then
        echo "obj-y += hmbird_patch.o" >> Makefile || error "写入Makefile失败"
    fi

    info "HMBird补丁应用成功！"
}

# 主流程
apply_hmbird_patch
if [ "$ENABLE_LZ4KD" = "true"]; then
  cd kernel_workspace/kernel_platform/common
  info "更新LZ4实现"
  curl -sSLO https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/lib/lz4/lz4_decompress.c
  curl -sSLO https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/lib/lz4/lz4defs.h
  curl -sSLO https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/lib/lz4/lz4_compress.c
  curl -sSLO https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/lib/lz4/lz4hc_compress.c
  
  info "更新Zstd实现"
  mkdir -p lib/zstd && cd lib/zstd
  curl -sSL https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/lib/zstd/zstd_common_module.c -o common.c
  cd ../../..
  info "✅ LZ4/Zstd 算法更新完成"
fi
# 返回common目录
cd .. || error "返回common目录失败"
cd arch/arm64/configs || error "进入configs目录失败"
# 添加SUSFS配置
info "添加SUSFS配置..."
echo -e "CONFIG_KSU=y
CONFIG_KSU_SUSFS_SUS_SU=n
CONFIG_KSU_MANUAL_HOOK=y
CONFIG_KSU_SUSFS=y
CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y
CONFIG_KSU_SUSFS_SUS_PATH=y
CONFIG_KSU_SUSFS_SUS_MOUNT=y
CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=y
CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=y
CONFIG_KSU_SUSFS_SUS_KSTAT=y
CONFIG_KSU_SUSFS_TRY_UMOUNT=y
CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=y
CONFIG_KSU_SUSFS_SPOOF_UNAME=y
CONFIG_KSU_SUSFS_ENABLE_LOG=y
CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y
CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y
CONFIG_KSU_SUSFS_OPEN_REDIRECT=y
# 启用高级压缩支持
CONFIG_CRYPTO_LZ4HC=y
CONFIG_CRYPTO_LZ4=y
CONFIG_CRYPTO_ZSTD=y
# 文件系统级压缩支持
CONFIG_F2FS_FS_COMPRESSION=y
CONFIG_F2FS_FS_LZ4=y
CONFIG_F2FS_FS_LZ4HC=y
CONFIG_F2FS_FS_ZSTD=y
# 内核镜像压缩配置
CONFIG_KERNEL_LZ4=y
# BBR(TCP拥塞控制算法)
CONFIG_TCP_CONG_ADVANCED=y
CONFIG_TCP_CONG_BBR=y
CONFIG_NET_SCH_FQ=y
CONFIG_TCP_CONG_BIC=n
CONFIG_TCP_CONG_CUBIC=n
CONFIG_TCP_CONG_WESTWOOD=n
CONFIG_TCP_CONG_HTCP=n
CONFIG_DEFAULT_TCP_CONG=bbr

CONFIG_LOCALVERSION_AUTO=n" >> gki_defconfig

# 返回kernel_platform目录
cd $KERNEL_WORKSPACE/kernel_platform || error "返回kernel_platform目录失败"

# 移除check_defconfig
sudo sed -i 's/check_defconfig//' $KERNEL_WORKSPACE/kernel_platform/common/build.config.gki || error "修改build.config.gki失败"

# 添加KPM配置
if [ "$ENABLE_KPM" = true ]; then
    info "添加KPM配置..."
    echo "CONFIG_KPM=y" >> common/arch/arm64/configs/gki_defconfig
    sudo sed -i 's/check_defconfig//' common/build.config.gki || error "修改build.config.gki失败"
fi

# 修改内核名称
info "修改内核名称..."
sed -i 's/${scm_version}//' common/scripts/setlocalversion || error "修改setlocalversion失败"
sudo sed -i "s/-4k/${KERNEL_SUFFIX}/g" common/arch/arm64/configs/gki_defconfig || error "修改gki_defconfig失败"

# 应用完美风驰补丁
info "应用完美风驰补丁..."
cd $KERNEL_WORKSPACE/kernel_platform/
git clone https://github.com/HanKuCha/sched_ext.git
cp -r ./sched_ext/* ./common/kernel/sched
rm -rf ./sched_ext/.git
cd $KERNEL_WORKSPACE/kernel_platform/common/kernel/sched  || error "跳转sched目录失败"

# 构建内核
info "开始构建内核..."
export KBUILD_BUILD_TIMESTAMP="$KERNEL_TIME"
export PATH="$KERNEL_WORKSPACE/kernel_platform/prebuilts/clang/host/linux-x86/clang-r510928/bin:$PATH"
export PATH="/usr/lib/ccache:$PATH"

cd $KERNEL_WORKSPACE/kernel_platform/common || error "进入common目录失败"

make -j$(nproc --all) LLVM=1 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CC=clang \
  RUSTC=../../prebuilts/rust/linux-x86/1.73.0b/bin/rustc \
  PAHOLE=../../prebuilts/kernel-build-tools/linux-x86/bin/pahole \
  LD=ld.lld HOSTLD=ld.lld O=out KCFLAGS+=-O2 gki_defconfig || error "生成配置失败"


make -j$(nproc --all) LLVM=1 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CC=clang \
  RUSTC=../../prebuilts/rust/linux-x86/1.73.0b/bin/rustc \
  PAHOLE=../../prebuilts/kernel-build-tools/linux-x86/bin/pahole \
  LD=ld.lld HOSTLD=ld.lld O=out KCFLAGS+=-O2 Image || error "内核构建失败"



info "应用Linux补丁..."
cd out/arch/arm64/boot || error "进入boot目录失败"
curl -LO https://github.com/SukiSU-Ultra/SukiSU_KernelPatch_patch/releases/download/0.12.0/patch_linux || error "下载patch_linux失败"
chmod +x patch_linux
./patch_linux || error "应用patch_linux失败"
rm -f Image
mv oImage Image || error "替换Image失败"

# 创建AnyKernel3包
info "创建AnyKernel3包..."
cd "$WORKSPACE" || error "返回工作目录失败"
git clone -q https://github.com/showdo/AnyKernel3.git --depth=1 || info "AnyKernel3已存在"
rm -rf ./AnyKernel3/.git
rm -f ./AnyKernel3/push.sh
cp "$KERNEL_WORKSPACE/kernel_platform/common/out/arch/arm64/boot/Image" ./AnyKernel3/ || error "复制Image失败"

# 打包
cd AnyKernel3 || error "进入AnyKernel3目录失败"
zip -r "AnyKernel3_${KSU_VERSION}_${DEVICE_NAME}_SuKiSu.zip" ./* || error "打包失败"

# 创建C盘输出目录
WIN_OUTPUT_DIR="/mnt/c/Kernel_Build/${DEVICE_NAME}/"
mkdir -p "$WIN_OUTPUT_DIR" || error "无法创建Windows目录，可能未挂载C盘，将保存到Linux目录:$WORKSPACE/AnyKernel3/AnyKernel3_${KSU_VERSION}_${DEVICE_NAME}_SuKiSu.zip"

# 复制Image和AnyKernel3包
cp "$KERNEL_WORKSPACE/kernel_platform/common/out/arch/arm64/boot/Image" "$WIN_OUTPUT_DIR/"
cp "$WORKSPACE/AnyKernel3/AnyKernel3_${KSU_VERSION}_${DEVICE_NAME}_SuKiSu.zip" "$WIN_OUTPUT_DIR/"

rm -rf $WORKSPACE
info "内核包路径: C:/Kernel_Build/${DEVICE_NAME}/AnyKernel3_${KSU_VERSION}_${DEVICE_NAME}_SuKiSu.zip"
info "Image路径: C:/Kernel_Build/${DEVICE_NAME}/Image"
info "请在C盘目录中查找内核包和Image文件。"
