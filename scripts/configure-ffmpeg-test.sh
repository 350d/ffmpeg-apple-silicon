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
    --enable-ffmpeg

echo "✅ FFmpeg configuration complete!"
echo "📋 Configuration summary:"
echo "  - Architecture: ARM64"
echo "  - PIC enabled: Yes" 
echo "  - Everything disabled except ffmpeg binary"
echo "  - No filters, no formats - only version test" 