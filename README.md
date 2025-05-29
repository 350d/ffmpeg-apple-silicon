# FFmpeg for Apple Silicon

Native FFmpeg build optimized for Apple Silicon (M1/M2/M3) with VideoToolbox hardware acceleration.

## Architecture Overview

This project provides **two approaches** for FFmpeg builds:

### 🍎 **Native macOS** (Production)
- **Fast & Efficient**: Direct compilation on macOS runners
- **VideoToolbox**: Apple's native hardware acceleration
- **Static binaries**: Ready-to-use without dependencies
- **Trigger**: `git tag v3.x.x && git push origin v3.x.x`

### 🐳 **Docker Stages** (Development)  
- **Dependencies** → **Configure** → **Build** (3 separate stages)
- **Maximum caching**: Each stage caches independently
- **Easy debugging**: Test individual stages
- **Motion vectors verification**: Tested at each step

Choose native macOS for production releases, Docker for development and testing.

## Features

- **Native Apple Silicon compilation** - runs directly on macOS ARM64
- **VideoToolbox hardware acceleration** - leverages Apple's native video encoding/decoding
- **Motion vectors support** - advanced video analysis and computer vision
- **Static binaries** - no external dependencies required
- **GitHub Actions automation** - builds triggered on version tags

## Quick Start

1. Download the latest release from [Releases](../../releases)
2. Extract the binaries:
   ```bash
   tar -xzf ffmpeg-apple-silicon-native-*.tar.gz
   ```
3. Use the binaries:
   ```bash
   ./ffmpeg -i input.mp4 -c:v h264_videotoolbox output.mp4
   ```

## Hardware Acceleration

The binaries include VideoToolbox support for hardware-accelerated encoding/decoding:

- **H.264**: `-c:v h264_videotoolbox`
- **H.265/HEVC**: `-c:v hevc_videotoolbox` 
- **ProRes**: `-c:v prores_videotoolbox`

## Motion Vectors Analysis

The build includes full motion vectors support for advanced video analysis:

### Export Motion Vectors
```bash
# Export motion vectors as overlay
./ffmpeg -flags2 +export_mvs -i input.mp4 -vf codecview=mv=pf+bf+bb output_with_vectors.mp4

# Export motion vectors data to file
./ffmpeg -flags2 +export_mvs -i input.mp4 -vf codecview=mv=pf -f null - 2> motion_data.txt
```

### Frame Analysis
```bash
# Detailed frame information with motion vectors
./ffmpeg -i input.mp4 -vf showinfo -f null - 2> frame_analysis.log

# Combined motion vectors + frame info
./ffmpeg -flags2 +export_mvs -i input.mp4 -vf "codecview=mv=pf+bf,showinfo" -f null -
```

### Use Cases
- **Motion detection** - surveillance and security applications
- **Computer vision** - object tracking and movement analysis  
- **Video compression** - understanding encoding efficiency
- **Sports analysis** - player and ball tracking
- **Academic research** - video processing algorithms

## Building from Source

Binaries are automatically built via GitHub Actions when new version tags are pushed:

```bash
git tag v3.1.0
git push origin v3.1.0
```

This triggers a native macOS build with all optimizations and VideoToolbox support.

## Docker Development (Dependencies Testing)

For dependency testing and development purposes, there's also a Docker-based approach with separate stages:

### Staged Docker Build Process

The Docker build is split into three optimized stages for maximum caching efficiency:

1. **Dependencies** (`Dockerfile.deps`) - Install and verify all codec libraries
2. **Configure** (`Dockerfile.configure`) - Run FFmpeg configure with all options  
3. **Build** (`Dockerfile.build`) - Compile FFmpeg binaries

### Test Individual Stages
```bash
# Test dependencies only
./tmp/test-deps.sh

# Test configure stage
./tmp/test-configure.sh  

# Test full build
./tmp/test-build.sh

# Manual stage testing
docker build --platform linux/arm64 -f Dockerfile.deps -t ffmpeg-deps .
docker build --platform linux/arm64 -f Dockerfile.configure -t ffmpeg-configure .
docker build --platform linux/arm64 -f Dockerfile.build --build-arg BASE_IMAGE=ffmpeg-configure:latest -t ffmpeg-final .
```

### Benefits of Staged Approach
- ✅ **Maximum caching** - each stage caches independently
- ✅ **Fast iteration** - configure changes don't rebuild dependencies
- ✅ **Easy debugging** - test each stage separately
- ✅ **Motion vectors verification** - tested at each stage

### Download Built Binaries
```bash
# After running build tests, download artifacts:
./tmp/download-artifacts.sh

# Artifacts will be available in ./downloads/:
# - ffmpeg (binary)
# - ffprobe (binary) 
# - ffmpeg-linux-arm64-YYYYMMDD.tar.gz (archive)
# - checksums.txt (integrity verification)
```

The Docker dependencies setup stops before FFmpeg configure, focusing on:
- ✅ Stable dependency installation
- ✅ Comprehensive caching strategy  
- ✅ All codec libraries verification
- ✅ Motion vectors support readiness
- ✅ **Clean build output** (warnings suppressed)
- ✅ **Downloadable artifacts** with checksums

## Documentation

- **[Motion Vectors Guide](MOTION_VECTORS.md)** - Comprehensive motion vectors documentation with examples

## License

MIT License - see [LICENSE](LICENSE) file for details. 