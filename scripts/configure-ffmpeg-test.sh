#!/bin/bash

# Ultra-Fast FFmpeg Test Configuration
# Only for testing compilation and ffmpeg -version

set -e

echo "🧪 Configuring FFmpeg for version test only..."

./configure \
    --prefix=/opt/ffmpeg \
    --enable-pic \
    --arch=arm64 \
    --disable-shared \
    --enable-static \
    --disable-doc \
    --disable-debug \
    --disable-htmlpages \
    --disable-manpages \
    --disable-podpages \
    --disable-txtpages \
    --disable-network \
    --disable-autodetect \
    --disable-everything \
    --disable-avfilter \
    --disable-avformat \
    --disable-avcodec \
    --disable-avdevice \
    --disable-swscale \
    --disable-swresample \
    --disable-postproc \
    --enable-avutil \
    --enable-ffmpeg

echo "✅ FFmpeg configuration complete!"
echo "📋 Configuration summary:"
echo "  - Architecture: ARM64"
echo "  - PIC enabled: Yes" 
echo "  - Only avutil and ffmpeg binary"
echo "  - Minimal build for version test" 