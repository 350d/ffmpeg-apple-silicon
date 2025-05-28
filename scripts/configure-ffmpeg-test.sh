#!/bin/bash

# FFmpeg Test Configuration - Minimal build for quick testing
# This builds FFmpeg with only essential codecs for fast validation

set -e

if [[ -z "$FFMPEG_BUILD_ROOT" ]]; then
    echo "Error: FFMPEG_BUILD_ROOT environment variable is not set"
    exit 1
fi

if [[ -z "$BIN_DIR" ]]; then
    echo "Error: BIN_DIR environment variable is not set"
    exit 1
fi

echo "🧪 Configuring FFmpeg for QUICK TESTING..."

# Set up environment
export PKG_CONFIG_PATH="$FFMPEG_BUILD_ROOT/lib/pkgconfig"
export LDFLAGS="-L$FFMPEG_BUILD_ROOT/lib"
export CPPFLAGS="-I$FFMPEG_BUILD_ROOT/include"

# Minimal FFmpeg configure for testing
./configure \
  --prefix="$FFMPEG_BUILD_ROOT" \
  --bindir="$BIN_DIR" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$FFMPEG_BUILD_ROOT/include" \
  --extra-ldflags="-L$FFMPEG_BUILD_ROOT/lib" \
  --extra-libs="-lpthread -lm -lz" \
  \
  `# License options` \
  --enable-gpl \
  --enable-version3 \
  \
  `# Build options` \
  --enable-static \
  --disable-shared \
  --disable-debug \
  --enable-pic \
  --arch=arm64 \
  --cc=clang \
  \
  `# Core features` \
  --enable-avfilter \
  --enable-pthreads \
  --enable-runtime-cpudetect \
  \
  `# Programs` \
  --enable-ffmpeg \
  --enable-ffprobe \
  \
  `# Only essential codecs for quick test` \
  --enable-libx264 \
  \
  `# Disable everything else for speed` \
  --disable-ffplay \
  --disable-postproc \
  --disable-doc \
  --disable-htmlpages \
  --disable-manpages \
  --disable-podpages \
  --disable-txtpages \
  --disable-network \
  --disable-dct \
  --disable-dwt \
  --disable-error-resilience \
  --disable-lsp \
  --disable-mdct \
  --disable-rdft \
  --disable-fft \
  --disable-faan \
  --disable-pixelutils

echo "✅ FFmpeg configured for quick testing!"
echo "📋 Configuration saved to config.log"

# Save configuration for reference
cp config.h "$FFMPEG_BUILD_ROOT/ffmpeg-config-test.h" || true
cp config.log "$FFMPEG_BUILD_ROOT/ffmpeg-config-test.log" || true

echo ""
echo "⚡ Quick test build - only x264 codec included"
echo "🚀 Build time: ~5-10 minutes vs 2+ hours for full build" 