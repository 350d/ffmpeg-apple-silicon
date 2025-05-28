#!/bin/bash

# Test release build locally
set -e

echo "🚀 Testing release Docker build..."

# Build the release Docker image
echo "Building Docker image..."
docker build -t ffmpeg-release-test .

# Test basic functionality
echo "Testing basic functionality..."
docker run --rm ffmpeg-release-test ffmpeg -version
docker run --rm ffmpeg-release-test ffprobe -version
docker run --rm ffmpeg-release-test ffplay -version

# Create temporary container to extract binaries
echo "Extracting binaries..."
docker create --name temp_test_container ffmpeg-release-test
mkdir -p tmp/release-test
docker cp temp_test_container:/opt/ffmpeg/bin/ffmpeg tmp/release-test/
docker cp temp_test_container:/opt/ffmpeg/bin/ffprobe tmp/release-test/
docker cp temp_test_container:/opt/ffmpeg/bin/ffplay tmp/release-test/
docker rm temp_test_container

# Test extracted binaries
echo "Testing extracted binaries..."
chmod +x tmp/release-test/*
./tmp/release-test/ffmpeg -version
./tmp/release-test/ffprobe -version  
./tmp/release-test/ffplay -version

# Test encoding
echo "Testing H.264 encoding..."
./tmp/release-test/ffmpeg -f lavfi -i testsrc2=duration=3:size=320x240:rate=15 \
  -c:v libx264 -preset ultrafast tmp/release-test/test_h264.mp4

# Test motion vectors with modern API
echo "Testing motion vector export..."
./tmp/release-test/ffmpeg -f lavfi -i testsrc2=duration=1:size=160x120:rate=10 \
  -c:v libx264 -flags2 +export_mvs tmp/release-test/test_mv.mp4

# Create test archive
echo "Creating test archive..."
cd tmp/release-test
tar -czf ../ffmpeg-apple-silicon-test.tar.gz ffmpeg ffprobe ffplay
cd ../..

# Calculate checksum
sha256sum tmp/ffmpeg-apple-silicon-test.tar.gz > tmp/checksums-test.txt

echo "✅ Release test completed successfully!"
echo "📦 Test archive: tmp/ffmpeg-apple-silicon-test.tar.gz"
echo "🔍 Checksums: tmp/checksums-test.txt"
echo ""
echo "To clean up test files: rm -rf tmp/" 