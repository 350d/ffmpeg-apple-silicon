#!/bin/bash

# FFmpeg Configure Script Example - Extended Configuration
# This example shows how easy it is to add new codecs and features
# Copy this to configure-ffmpeg.sh and modify as needed

set -e

if [[ -z "$FFMPEG_BUILD_ROOT" ]]; then
    echo "Error: FFMPEG_BUILD_ROOT environment variable is not set"
    exit 1
fi

if [[ -z "$BIN_DIR" ]]; then
    echo "Error: BIN_DIR environment variable is not set"
    exit 1
fi

echo "🔧 Configuring FFmpeg with EXTENDED options..."

# Set up environment
export PKG_CONFIG_PATH="$FFMPEG_BUILD_ROOT/lib/pkgconfig"
export LDFLAGS="-L$FFMPEG_BUILD_ROOT/lib"
export CPPFLAGS="-I$FFMPEG_BUILD_ROOT/include"

# FFmpeg configure command with extended codec support
./configure \
  --prefix="$FFMPEG_BUILD_ROOT" \
  --bindir="$BIN_DIR" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$FFMPEG_BUILD_ROOT/include" \
  --extra-ldflags="-L$FFMPEG_BUILD_ROOT/lib" \
  --extra-libs="-lpthread -lm -lz -liconv" \
  \
  `# License options` \
  --enable-gpl \
  --enable-version3 \
  --enable-nonfree \
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
  --enable-postproc \
  --enable-pthreads \
  --enable-runtime-cpudetect \
  \
  `# Programs` \
  --enable-ffmpeg \
  --enable-ffprobe \
  --enable-ffplay \
  \
  `# Apple Hardware Acceleration` \
  --enable-videotoolbox \
  --enable-audiotoolbox \
  --enable-coreimage \
  --enable-appkit \
  --enable-avfoundation \
  --enable-metal \
  \
  `# Video Codecs - Core` \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libaom \
  --enable-libsvtav1 \
  --enable-libkvazaar \
  \
  `# Video Codecs - Additional (uncomment to enable)` \
  # --enable-librav1e \
  # --enable-libtheora \
  # --enable-libxvid \
  # --enable-libopenh264 \
  \
  `# Audio Codecs - Core` \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libflac \
  \
  `# Audio Codecs - Additional (uncomment to enable)` \
  # --enable-libfdk-aac \
  # --enable-libtwolame \
  # --enable-libspeex \
  # --enable-libshine \
  # --enable-libvo-amrwbenc \
  \
  `# Image/Subtitle Support` \
  --enable-libwebp \
  --enable-libopenjpeg \
  --enable-libass \
  \
  `# Text Rendering` \
  --enable-libfreetype \
  --enable-libfontconfig \
  --enable-libfribidi \
  --enable-libharfbuzz \
  \
  `# Video Processing and Filters` \
  --enable-libvidstab \
  --enable-libzimg \
  \
  `# Advanced Filters (uncomment to enable)` \
  # --enable-libopencv \
  # --enable-libtensorflow \
  # --enable-librubberband \
  # --enable-libebur128 \
  # --enable-liblensfun \
  # --enable-libvmaf \
  \
  `# Container Support` \
  --enable-libbluray \
  \
  `# Network and Streaming (uncomment to enable)` \
  # --enable-libsrt \
  # --enable-libzmq \
  # --enable-libssh \
  # --enable-librtmp \
  \
  `# Hardware Acceleration - Linux/Windows (uncomment to enable)` \
  # --enable-nvenc \
  # --enable-nvdec \
  # --enable-cuda \
  # --enable-cuvid \
  # --enable-vaapi \
  # --enable-vdpau \
  # --enable-qsv \
  # --enable-amf \
  # --enable-opencl \
  \
  `# Additional Features (uncomment to enable)` \
  # --enable-chromaprint \
  # --enable-libbs2b \
  # --enable-libcaca \
  # --enable-libcdio \
  # --enable-libdc1394 \
  # --enable-libgme \
  # --enable-libmodplug \
  # --enable-libpulse \
  # --enable-libv4l2 \
  # --enable-libxcb \

echo "✅ FFmpeg configured successfully with extended options!"
echo "📋 Configuration saved to config.log"

# Show configuration summary
echo ""
echo "🔍 Configuration Summary:"
echo "========================="
./ffbuild/config.sh | head -30

# Save configuration for reference
cp config.h "$FFMPEG_BUILD_ROOT/ffmpeg-config.h" || true
cp config.log "$FFMPEG_BUILD_ROOT/ffmpeg-config.log" || true

echo ""
echo "💡 To customize:"
echo "1. Copy this file to configure-ffmpeg.sh"
echo "2. Uncomment desired codecs/features"
echo "3. Add required dependencies to Dockerfile and build-dependencies.sh"
echo "4. Build with: docker build ." 