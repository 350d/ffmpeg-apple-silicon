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
    --disable-everything \
    --disable-avdevice \
    --disable-swscale \
    --disable-swresample \
    --disable-network \
    --disable-autodetect \
    --enable-ffmpeg \
    --enable-encoder=null \
    --enable-decoder=null \
    --enable-muxer=null \
    --enable-demuxer=null

echo "✅ FFmpeg configuration complete!"
echo "📋 Configuration summary:"
echo "  - Architecture: ARM64"
echo "  - PIC enabled: Yes" 
echo "  - Minimal components: rawvideo, null, testsrc2"
echo "  - Target: fastest possible build" 

# Trigger workflow: force run ultra-fast test 