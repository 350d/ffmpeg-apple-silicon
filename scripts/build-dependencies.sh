#!/bin/bash

# FFmpeg Dependencies Build Script
# This script builds all required libraries for FFmpeg

set -e

# Suppress all compiler warnings and build noise
export CFLAGS="-w -O2"
export CXXFLAGS="-w -O2"
export CPPFLAGS="-w"
export LDFLAGS="-w"

if [[ -z "$FFMPEG_BUILD_ROOT" ]]; then
    echo "Error: FFMPEG_BUILD_ROOT environment variable is not set"
    exit 1
fi

if [[ -z "$SOURCE_DIR" ]]; then
    echo "Error: SOURCE_DIR environment variable is not set"
    exit 1
fi

echo "🔨 Building FFmpeg dependencies..."
echo "Build root: $FFMPEG_BUILD_ROOT"
echo "Source directory: $SOURCE_DIR"

# Progress tracking
TOTAL_DEPS=20
CURRENT_DEP=0

progress() {
    ((CURRENT_DEP++))
    echo "🔄 Progress: [$CURRENT_DEP/$TOTAL_DEPS] $1"
}

cd "$SOURCE_DIR"

# Function to build a library
build_lib() {
    local name="$1"
    local source_dir="$2"
    local configure_cmd="$3"
    local cmake_build="$4"
    
    progress "Building $name..."
    cd "$SOURCE_DIR/$source_dir"
    
    if [[ "$cmake_build" == "true" ]]; then
        # CMake build
        mkdir -p build && cd build
        eval "$configure_cmd"
        make -j$(nproc) >/dev/null 2>&1
        make install >/dev/null 2>&1
    else
        # Autotools build
        if [[ "$configure_cmd" ]]; then
            eval "./configure --prefix=$FFMPEG_BUILD_ROOT $configure_cmd" >/dev/null 2>&1
        else
            ./configure --prefix="$FFMPEG_BUILD_ROOT" --disable-shared --enable-static >/dev/null 2>&1
        fi
        make -j$(nproc) >/dev/null 2>&1
        make install >/dev/null 2>&1
    fi
    
    echo "✅ Completed $name"
}

# Core libraries
build_lib "zlib" "zlib-*" "--static"
build_lib "libiconv" "libiconv-*" "--disable-shared --enable-static"

# Audio codecs
build_lib "LAME" "lame-*" "--disable-shared --enable-static --disable-dependency-tracking"
build_lib "Opus" "opus-*" "--disable-shared --enable-static --disable-doc"
build_lib "libogg" "libogg-*" "--disable-shared --enable-static"
build_lib "libvorbis" "libvorbis-*" "--disable-shared --enable-static --with-ogg=$FFMPEG_BUILD_ROOT"
build_lib "FLAC" "flac-*" "--disable-shared --enable-static --disable-doxygen-docs --disable-xmms-plugin"

# Video codecs
build_lib "x264" "x264" "--enable-static --enable-pic --disable-cli"

# x265 (special CMake handling)
progress "Building x265..."
cd "$SOURCE_DIR/x265_"*/build/linux
cmake -G "Unix Makefiles" \
    -DCMAKE_INSTALL_PREFIX="$FFMPEG_BUILD_ROOT" \
    -DENABLE_SHARED=OFF \
    -DENABLE_CLI=OFF \
    -DHIGH_BIT_DEPTH=ON \
    ../../source >/dev/null 2>&1
make -j$(nproc) >/dev/null 2>&1
make install >/dev/null 2>&1
echo "✅ Completed x265"

build_lib "libvpx" "libvpx" "--disable-shared --enable-static --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm"

# AOM (CMake)
progress "Building AOM..."
cd "$SOURCE_DIR/aom"
mkdir -p build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX="$FFMPEG_BUILD_ROOT" \
    -DBUILD_SHARED_LIBS=0 \
    -DENABLE_EXAMPLES=0 \
    -DENABLE_TOOLS=0 \
    -DENABLE_TESTS=0 \
    -DENABLE_DOCS=0 >/dev/null 2>&1
make -j$(nproc) >/dev/null 2>&1
make install >/dev/null 2>&1
echo "✅ Completed AOM"

# SVT-AV1 (CMake)
progress "Building SVT-AV1..."
cd "$SOURCE_DIR/SVT-AV1"
mkdir -p build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX="$FFMPEG_BUILD_ROOT" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_DEC=OFF \
    -DBUILD_SHARED_LIBS=OFF >/dev/null 2>&1
make -j$(nproc) >/dev/null 2>&1
make install >/dev/null 2>&1
echo "✅ Completed SVT-AV1"

# Image formats
build_lib "libwebp" "libwebp-*" "--disable-shared --enable-static"

# OpenJPEG (CMake)
echo "📦 Building OpenJPEG..."
cd "$SOURCE_DIR/openjpeg-"*
mkdir -p build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX="$FFMPEG_BUILD_ROOT" \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_CODEC=OFF
make -j$(nproc)
make install
echo "✅ Completed OpenJPEG"

# Text rendering (order matters due to dependencies)
build_lib "FreeType" "freetype-*" "--disable-shared --enable-static --with-harfbuzz=no"
build_lib "FriBidi" "fribidi-*" "--disable-shared --enable-static"
build_lib "HarfBuzz" "harfbuzz-*" "--disable-shared --enable-static --with-freetype=yes --with-glib=no --with-gobject=no"
build_lib "Fontconfig" "fontconfig-*" "--disable-shared --enable-static --disable-docs"
build_lib "libass" "libass-*" "--disable-shared --enable-static"

# Video processing
# vid.stab (CMake)
echo "📦 Building vid.stab..."
cd "$SOURCE_DIR/vid.stab"
mkdir -p build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX="$FFMPEG_BUILD_ROOT" \
    -DBUILD_SHARED_LIBS=OFF
make -j$(nproc)
make install
echo "✅ Completed vid.stab"

# zimg
echo "📦 Building zimg..."
cd "$SOURCE_DIR/zimg-"*
./autogen.sh
./configure --prefix="$FFMPEG_BUILD_ROOT" --disable-shared --enable-static
make -j$(nproc)
make install
echo "✅ Completed zimg"

# kvazaar
echo "📦 Building kvazaar..."
cd "$SOURCE_DIR/kvazaar"
./autogen.sh
./configure --prefix="$FFMPEG_BUILD_ROOT" --disable-shared --enable-static
make -j$(nproc)
make install
echo "✅ Completed kvazaar"

# Container formats
echo "📦 Building libbluray..."
cd "$SOURCE_DIR/libbluray"
./bootstrap
./configure --prefix="$FFMPEG_BUILD_ROOT" --disable-shared --enable-static --disable-dependency-tracking --disable-silent-rules --without-libxml2 --without-freetype --disable-doxygen-doc --disable-bdjava-jar
make -j$(nproc)
make install
echo "✅ Completed libbluray"

# SDL2 for ffplay
build_lib "SDL2" "SDL2-*" "--disable-shared --enable-static"

echo ""
echo "🎉 All dependencies built successfully!"
echo "📁 Libraries installed in: $FFMPEG_BUILD_ROOT/lib"
echo "📁 Headers installed in: $FFMPEG_BUILD_ROOT/include"
echo ""

# Show some stats
echo "📊 Library count: $(ls -1 $FFMPEG_BUILD_ROOT/lib/*.a 2>/dev/null | wc -l)"
echo "📊 Total size: $(du -sh $FFMPEG_BUILD_ROOT/lib 2>/dev/null | cut -f1)" 