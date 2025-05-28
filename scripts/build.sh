#!/bin/bash

# FFmpeg Apple Silicon Build Script
# Based on: http://www.osxexperts.net

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running on Apple Silicon
if [[ $(uname -m) != "arm64" ]]; then
    echo_error "This script requires Apple Silicon (ARM64) macOS"
    exit 1
fi

# Check if Xcode Command Line Tools are installed
if ! xcode-select -p &> /dev/null; then
    echo_error "Xcode Command Line Tools are required. Install with: xcode-select --install"
    exit 1
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo_error "Homebrew is required. Install from: https://brew.sh"
    exit 1
fi

echo_info "Starting FFmpeg build for Apple Silicon..."

# Setup build environment
BUILD_ROOT="$HOME/ffmpeg-build-$(date +%Y%m%d)"
SOURCE_DIR="$BUILD_ROOT/source"
BIN_DIR="$BUILD_ROOT/bin"

mkdir -p "$SOURCE_DIR"
mkdir -p "$BIN_DIR"

export PATH="$BUILD_ROOT/bin:$PATH"
export PKG_CONFIG_PATH="$BUILD_ROOT/lib/pkgconfig"
export MACOSX_DEPLOYMENT_TARGET="11.0"

echo_info "Build directory: $BUILD_ROOT"

# Install dependencies via Homebrew
echo_info "Installing build dependencies..."
brew install automake autoconf libtool pkg-config cmake nasm yasm ninja meson

# Function to build a library
build_lib() {
    local name="$1"
    local url="$2" 
    local configure_opts="$3"
    local build_dir="$4"
    
    echo_info "Building $name..."
    
    cd "$SOURCE_DIR"
    
    if [[ "$url" == git://* ]] || [[ "$url" == https://*git* ]]; then
        # Git repository
        local repo_name=$(basename "$url" .git)
        if [[ ! -d "$repo_name" ]]; then
            git clone --depth 1 "$url"
        fi
        cd "$repo_name"
    else
        # Archive
        local archive_name=$(basename "$url")
        if [[ ! -f "$archive_name" ]]; then
            curl -L "$url" -o "$archive_name"
            tar -xf "$archive_name"
        fi
        local extract_dir=$(tar -tf "$archive_name" | head -1 | cut -f1 -d"/")
        cd "$extract_dir"
    fi
    
    if [[ -n "$build_dir" ]]; then
        mkdir -p "$build_dir" && cd "$build_dir"
    fi
    
    if [[ "$configure_opts" == cmake* ]]; then
        eval "$configure_opts"
        make -j$(sysctl -n hw.ncpu)
        make install
    else
        eval "./configure --prefix=$BUILD_ROOT $configure_opts"
        make -j$(sysctl -n hw.ncpu)
        make install
    fi
    
    echo_success "Completed $name"
}

# Build libraries
build_lib "zlib" "https://github.com/madler/zlib/archive/refs/tags/v1.3.tar.gz" "--static"

build_lib "libiconv" "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.17.tar.gz" "--disable-shared --enable-static"

build_lib "LAME" "https://downloads.sourceforge.net/lame/lame-3.100.tar.gz" "--disable-shared --enable-static --disable-dependency-tracking"

build_lib "Opus" "https://archive.mozilla.org/pub/opus/opus-1.4.tar.gz" "--disable-shared --enable-static --disable-doc"

build_lib "libogg" "https://downloads.xiph.org/releases/ogg/libogg-1.3.5.tar.gz" "--disable-shared --enable-static"

build_lib "libvorbis" "https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.gz" "--disable-shared --enable-static --with-ogg=$BUILD_ROOT"

build_lib "x264" "https://code.videolan.org/videolan/x264.git" "--enable-static --enable-pic --disable-cli"

# x265 (requires special handling)
echo_info "Building x265..."
cd "$SOURCE_DIR"
if [[ ! -f "x265_3.5.tar.gz" ]]; then
    curl -L "https://bitbucket.org/multicoreware/x265/downloads/x265_3.5.tar.gz" -o x265_3.5.tar.gz
    tar -xf x265_3.5.tar.gz
fi
cd x265_*/build/linux
cmake -G "Unix Makefiles" \
    -DCMAKE_INSTALL_PREFIX="$BUILD_ROOT" \
    -DENABLE_SHARED=OFF \
    -DENABLE_CLI=OFF \
    -DHIGH_BIT_DEPTH=ON \
    ../../source
make -j$(sysctl -n hw.ncpu)
make install
echo_success "Completed x265"

build_lib "libvpx" "https://chromium.googlesource.com/webm/libvpx.git" "--disable-shared --enable-static --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm"

# AOM
echo_info "Building AOM..."
cd "$SOURCE_DIR"
if [[ ! -d "aom" ]]; then
    git clone --depth 1 https://aomedia.googlesource.com/aom.git
fi
cd aom
mkdir -p build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX="$BUILD_ROOT" \
    -DBUILD_SHARED_LIBS=0 \
    -DENABLE_EXAMPLES=0 \
    -DENABLE_TOOLS=0 \
    -DENABLE_TESTS=0 \
    -DENABLE_DOCS=0
make -j$(sysctl -n hw.ncpu)
make install
echo_success "Completed AOM"

build_lib "libwebp" "https://github.com/webmproject/libwebp/archive/refs/tags/v1.3.2.tar.gz" "--disable-shared --enable-static"

build_lib "FreeType" "https://download.savannah.gnu.org/releases/freetype/freetype-2.13.2.tar.xz" "--disable-shared --enable-static --with-harfbuzz=no"

build_lib "libass" "https://github.com/libass/libass/releases/download/0.17.1/libass-0.17.1.tar.xz" "--disable-shared --enable-static"

# SDL2 for ffplay
build_lib "SDL2" "https://github.com/libsdl-org/SDL/releases/download/release-2.28.5/SDL2-2.28.5.tar.gz" "--disable-shared --enable-static"

# FFmpeg
echo_info "Building FFmpeg..."
cd "$SOURCE_DIR"
if [[ ! -d "ffmpeg" ]]; then
    git clone --depth 1 https://git.ffmpeg.org/ffmpeg.git
fi
cd ffmpeg

export PKG_CONFIG_PATH="$BUILD_ROOT/lib/pkgconfig"
export LDFLAGS="-L$BUILD_ROOT/lib"
export CPPFLAGS="-I$BUILD_ROOT/include"

./configure \
    --prefix="$BUILD_ROOT" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I$BUILD_ROOT/include" \
    --extra-ldflags="-L$BUILD_ROOT/lib" \
    --extra-libs="-lpthread -lm -lz -liconv" \
    --bindir="$BIN_DIR" \
    --enable-gpl \
    --enable-version3 \
    --enable-static \
    --disable-shared \
    --disable-debug \
    --enable-pic \
    --enable-libass \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libwebp \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libaom \
    --enable-ffplay \
    --enable-ffprobe \
    --enable-avfilter \
    --enable-postproc \
    --enable-pthreads \
    --enable-runtime-cpudetect \
    --enable-videotoolbox \
    --enable-audiotoolbox \
    --enable-coreimage \
    --enable-appkit \
    --enable-avfoundation \
    --enable-metal \
    --arch=arm64 \
    --cc=clang

make -j$(sysctl -n hw.ncpu)
make install

echo_success "Completed FFmpeg"

# Test the build
echo_info "Testing FFmpeg build..."
"$BIN_DIR/ffmpeg" -version
"$BIN_DIR/ffprobe" -version
"$BIN_DIR/ffplay" -version

echo_info "Available hardware accelerators:"
"$BIN_DIR/ffmpeg" -hide_banner -hwaccels

# Strip binaries
echo_info "Stripping binaries..."
strip "$BIN_DIR/ffmpeg"
strip "$BIN_DIR/ffprobe" 
strip "$BIN_DIR/ffplay"

# Create package
echo_info "Creating package..."
cd "$BIN_DIR"

cat > ffmpeg-info.txt << EOF
FFmpeg static build for Apple Silicon (ARM64)
Build date: $(date)
FFmpeg version: $("$BIN_DIR/ffmpeg" -version | head -n1)
Build directory: $BUILD_ROOT

Hardware acceleration: VideoToolbox, AudioToolbox

Included libraries:
- x264, x265 (H.264/H.265 encoding)
- libvpx (VP8/VP9)
- libaom (AV1)
- libass (subtitle rendering)
- libfreetype (text rendering)
- libmp3lame (MP3 encoding)
- libopus (Opus audio)
- libvorbis (Vorbis audio)
- libwebp (WebP images)

Usage examples:
./ffmpeg -hwaccel videotoolbox -i input.mp4 -c:v h264_videotoolbox output.mp4
./ffmpeg -i input.mp4 -c:v libx264 -crf 23 output.mp4
./ffmpeg -i input.mp4 -c:v libaom-av1 -crf 30 output.webm
EOF

tar -czf "ffmpeg-apple-silicon-$(date +%Y%m%d).tar.gz" ffmpeg ffprobe ffplay ffmpeg-info.txt

echo_success "Build completed successfully!"
echo_info "Binaries location: $BIN_DIR"
echo_info "Package: $BIN_DIR/ffmpeg-apple-silicon-$(date +%Y%m%d).tar.gz"
echo_warning "Remember to sign the binaries if needed:"
echo "  codesign -s - ffmpeg ffprobe ffplay" 