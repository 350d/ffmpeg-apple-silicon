#!/bin/bash

# FFmpeg Build Script for Fast Minimal Version
set -e

echo "🚀 Building FFmpeg with fast minimal configuration..."

# Download FFmpeg as archive for faster/more reliable download
cd /tmp
echo "📥 Downloading FFmpeg archive..."
curl -L "https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2" -o ffmpeg.tar.bz2
echo "📦 Extracting FFmpeg..."
tar -xjf ffmpeg.tar.bz2
rm ffmpeg.tar.bz2

# The archive already creates an 'ffmpeg' directory, no need to rename
echo "✅ FFmpeg extracted successfully"

cd ffmpeg

# Configure FFmpeg with only essential libraries (x264, lame)
echo "🔧 Configuring FFmpeg with minimal features..."
./configure \
  --prefix="$FFMPEG_BUILD_ROOT" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$FFMPEG_BUILD_ROOT/include" \
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
  --enable-libmp3lame \
  --enable-pic

echo "🔧 FFmpeg configuration completed"

# Build with limited parallelism to avoid resource exhaustion
echo "🏗️  Starting FFmpeg compilation..."
make -j2

echo "📦 Installing FFmpeg..."
make install

echo "✅ FFmpeg build completed successfully!"

# Cleanup
cd /
rm -rf /tmp/ffmpeg

echo "🎉 Fast minimal FFmpeg with H.264 & MP3 support is ready!" 