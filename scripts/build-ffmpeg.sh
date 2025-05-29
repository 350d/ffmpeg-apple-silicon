#!/bin/bash

# FFmpeg Build Script for Multi-Layer Architecture
set -e

echo "🚀 Building FFmpeg with cached dependencies..."

cd /tmp/ffmpeg

# Configure FFmpeg with all available libraries
./configure \
  --prefix="$FFMPEG_BUILD_ROOT" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$FFMPEG_BUILD_ROOT/include -w" \
  --extra-ldflags="-L$FFMPEG_BUILD_ROOT/lib" \
  --extra-libs="-lpthread -lm" \
  --ld="g++" \
  --bindir="$FFMPEG_BUILD_ROOT/bin" \
  --enable-static \
  --disable-shared \
  --disable-debug \
  --disable-ffplay \
  --enable-gpl \
  --enable-version3 \
  --enable-nonfree \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libaom \
  --enable-libsvtav1 \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libass \
  --enable-libfreetype \
  --enable-libfribidi \
  --enable-pic

echo "🔧 FFmpeg configuration completed"

# Build FFmpeg
echo "🔨 Building FFmpeg..."
make -j$(nproc)

echo "📦 Installing FFmpeg..."
make install

echo "✅ FFmpeg build completed successfully!"

# Show build info
echo "📋 Build summary:"
echo "FFmpeg version: $(${FFMPEG_BUILD_ROOT}/bin/ffmpeg -version | head -1)"
echo "Installed binaries:"
ls -la ${FFMPEG_BUILD_ROOT}/bin/
echo "Libraries used:"
ls -la ${FFMPEG_BUILD_ROOT}/lib/*.a | wc -l
echo "Total size: $(du -sh ${FFMPEG_BUILD_ROOT} | cut -f1)"

# Test the build
echo "🧪 Testing FFmpeg build..."
"$FFMPEG_BUILD_ROOT/bin/ffmpeg" -version
"$FFMPEG_BUILD_ROOT/bin/ffprobe" -version

echo "🎉 All done!" 