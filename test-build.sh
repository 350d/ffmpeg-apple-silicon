#!/bin/bash

# Quick Test Build Script
# Tests FFmpeg configuration changes in ~5-10 minutes instead of 2+ hours

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_TAG="ffmpeg-test:local"

echo "🚀 FFmpeg Quick Test Build"
echo "=========================="
echo "This builds a minimal FFmpeg with only x264 for fast testing"
echo "Build time: ~5-10 minutes vs 2+ hours for full build"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    echo "Please install Docker to use quick testing"
    exit 1
fi

# Check if scripts exist
if [[ ! -f "$SCRIPT_DIR/scripts/configure-ffmpeg-test.sh" ]]; then
    echo "❌ Test configuration script not found"
    echo "Make sure you're running this from the project root"
    exit 1
fi

# Make scripts executable
chmod +x "$SCRIPT_DIR/scripts/configure-ffmpeg-test.sh" 2>/dev/null || true

echo "🔨 Building test image..."
echo "Using: Dockerfile.test"
echo ""

# Build test image
if docker build -f Dockerfile.test -t "$TEST_TAG" "$SCRIPT_DIR"; then
    echo ""
    echo "✅ Build completed successfully!"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi

echo ""
echo "🧪 Running tests..."
echo "==================="

# Test 1: Basic functionality
echo "Test 1: FFmpeg version"
if docker run --rm "$TEST_TAG" ffmpeg -version > /dev/null; then
    echo "✅ FFmpeg version check passed"
else
    echo "❌ FFmpeg version check failed"
    exit 1
fi

# Test 2: Encoding test
echo "Test 2: Basic encoding"
if docker run --rm "$TEST_TAG" \
    ffmpeg -f lavfi -i testsrc2=duration=1:size=320x240:rate=10 \
    -c:v libx264 -preset ultrafast -f null /dev/null > /dev/null 2>&1; then
    echo "✅ Basic encoding test passed"
else
    echo "❌ Basic encoding test failed"
    exit 1
fi

# Test 3: Motion vector export
echo "Test 3: Motion vector export"
if docker run --rm "$TEST_TAG" \
    ffmpeg -flags2 +export_mvs -f lavfi -i testsrc2=duration=0.5:size=160x120:rate=5 \
    -c:v libx264 -f null /dev/null > /dev/null 2>&1; then
    echo "✅ Motion vector export test passed"
else
    echo "❌ Motion vector export test failed"
    exit 1
fi

# Test 4: Configuration validation
echo "Test 4: Configuration validation"
if docker run --rm "$TEST_TAG" \
    ffmpeg -hide_banner -encoders 2>/dev/null | grep -q "libx264"; then
    echo "✅ x264 encoder found"
else
    echo "❌ x264 encoder not found"
    exit 1
fi

echo ""
echo "🎉 All tests passed!"
echo "==================="
echo ""
echo "Your configuration changes work correctly!"
echo "You can now:"
echo "1. Commit your changes"
echo "2. Push to trigger full build"
echo "3. Or test locally with: docker run --rm $TEST_TAG ffmpeg [options]"
echo ""

# Optional: Clean up
read -p "Clean up test image? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker rmi "$TEST_TAG" > /dev/null 2>&1 || true
    echo "🗑️ Test image cleaned up"
fi

echo ""
echo "⚡ Quick test completed in $(date)" 