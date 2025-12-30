#!/bin/bash
# OpenSSL for HarmonyOS 交叉编译脚本 (Windows Git Bash 版本)
# 用于为 SQLCipher 提供加密库支持

set -e

# 配置参数
OPENSSL_VERSION="3.0.13"
OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
OUTPUT_DIR="${SCRIPT_DIR}/openssl"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 HarmonyOS NDK 环境
check_ndk() {
    log_info "检查 HarmonyOS NDK 环境..."

    if [ -z "$OHOS_NDK" ]; then
        log_error "未设置 OHOS_NDK 环境变量！"
        log_info "请设置 HarmonyOS SDK 路径，例如："
        log_info "export OHOS_NDK=\"/e/DevEco Studio/sdk/default/openharmony/native\""
        log_info ""
        log_info "根据您的 DevEco Studio 安装路径，建议使用："

        # 尝试自动检测
        if [ -d "/e/DevEco Studio/sdk/default/openharmony/native" ]; then
            log_warn "检测到 NDK 路径: /e/DevEco Studio/sdk/default/openharmony/native"
            log_info "请执行: export OHOS_NDK=\"/e/DevEco Studio/sdk/default/openharmony/native\""
        fi

        exit 1
    fi

    if [ ! -d "$OHOS_NDK" ]; then
        log_error "OHOS_NDK 路径不存在：$OHOS_NDK"
        exit 1
    fi

    # Windows 下检查 clang.exe
    if [ ! -f "$OHOS_NDK/llvm/bin/clang.exe" ] && [ ! -f "$OHOS_NDK/llvm/bin/clang" ]; then
        log_error "找不到 clang 编译器：$OHOS_NDK/llvm/bin/"
        exit 1
    fi

    log_info "✓ HarmonyOS NDK 环境检查通过：$OHOS_NDK"
}

# 检查编译工具
check_tools() {
    log_info "检查编译工具..."

    local missing_tools=()

    if ! command -v tar &> /dev/null; then
        missing_tools+=("tar")
    fi

    if ! command -v make &> /dev/null; then
        missing_tools+=("make")
    fi

    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing_tools+=("curl 或 wget")
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "缺少必要工具: ${missing_tools[*]}"
        log_info ""
        log_info "请安装这些工具："
        log_info "1. 安装 MSYS2: https://www.msys2.org/"
        log_info "2. 在 MSYS2 中执行: pacman -S make tar"
        exit 1
    fi

    log_info "✓ 编译工具检查通过"
}

# 下载 OpenSSL 源码
download_openssl() {
    log_info "下载 OpenSSL ${OPENSSL_VERSION}..."

    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    if [ -f "openssl-${OPENSSL_VERSION}.tar.gz" ]; then
        log_warn "OpenSSL 源码已存在，跳过下载"
    else
        log_info "从 ${OPENSSL_URL} 下载..."

        # 优先使用 curl，回退到 wget
        if command -v curl &> /dev/null; then
            curl -L -o "openssl-${OPENSSL_VERSION}.tar.gz" "$OPENSSL_URL"
        elif command -v wget &> /dev/null; then
            wget "$OPENSSL_URL" -O "openssl-${OPENSSL_VERSION}.tar.gz"
        else
            log_error "curl 和 wget 都不可用！"
            exit 1
        fi
    fi

    log_info "解压源码..."
    tar -xzf "openssl-${OPENSSL_VERSION}.tar.gz"

    log_info "✓ OpenSSL 源码准备完成"
}

# 编译 OpenSSL for arm64-v8a
build_arm64() {
    log_info "开始编译 arm64-v8a..."

    cd "$BUILD_DIR/openssl-${OPENSSL_VERSION}"

    # 清理之前的编译
    make clean 2>/dev/null || true

    # 设置交叉编译环境 (Windows 路径处理)
    export PATH="$OHOS_NDK/llvm/bin:$PATH"
    export CC="clang"
    export AR="llvm-ar"
    export RANLIB="llvm-ranlib"
    export CFLAGS="--target=aarch64-linux-ohos -D__MUSL__"

    # 配置编译选项（OpenSSL 3.x 兼容）
    ./Configure linux-aarch64 \
        --prefix="${OUTPUT_DIR}/arm64-v8a" \
        --openssldir="${OUTPUT_DIR}/arm64-v8a/ssl" \
        no-shared \
        no-tests \
        -D__MUSL__

    # 获取 CPU 核心数
    NPROC=$(nproc 2>/dev/null || echo "4")

    # 编译和安装
    make -j${NPROC}
    make install_sw install_ssldirs

    log_info "✓ arm64-v8a 编译完成"
}

# 编译 OpenSSL for x86_64
build_x86_64() {
    log_info "开始编译 x86_64..."

    cd "$BUILD_DIR/openssl-${OPENSSL_VERSION}"

    # 清理之前的编译
    make clean 2>/dev/null || true

    # 设置交叉编译环境
    export PATH="$OHOS_NDK/llvm/bin:$PATH"
    export CC="clang"
    export AR="llvm-ar"
    export RANLIB="llvm-ranlib"
    export CFLAGS="--target=x86_64-linux-ohos -D__MUSL__"

    # 配置编译选项（OpenSSL 3.x 兼容）
    ./Configure linux-x86_64 \
        --prefix="${OUTPUT_DIR}/x86_64" \
        --openssldir="${OUTPUT_DIR}/x86_64/ssl" \
        no-shared \
        no-tests \
        -D__MUSL__

    # 获取 CPU 核心数
    NPROC=$(nproc 2>/dev/null || echo "4")

    # 编译和安装
    make -j${NPROC}
    make install_sw install_ssldirs

    log_info "✓ x86_64 编译完成"
}

# 显示输出信息
show_output_info() {
    log_info "================================================"
    log_info "OpenSSL 编译成功！"
    log_info "================================================"
}

# 主函数
main() {
    log_info "开始为 HarmonyOS 编译 OpenSSL (Windows Git Bash)..."

    check_ndk
    check_tools
    download_openssl
    build_arm64
    build_x86_64
    show_output_info

    log_info "全部完成！"
}

# 运行主函数
main
