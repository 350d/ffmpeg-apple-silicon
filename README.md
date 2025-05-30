# FFmpeg for Apple Silicon

Native FFmpeg build optimized for Apple Silicon (M1/M2/M3) with VideoToolbox hardware acceleration.

## Features

- **Native Apple Silicon compilation** - runs directly on macOS ARM64
- **VideoToolbox hardware acceleration** - leverages Apple's native video encoding/decoding
- **Motion vectors support** - advanced video analysis and computer vision
- **Static binaries** - no external dependencies required
- **GitHub Actions automation** - builds triggered on version tags
- **Optimized caching** - fast CI builds with Homebrew and source caching

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

## Documentation

- **[Motion Vectors Guide](MOTION_VECTORS.md)** - Comprehensive motion vectors documentation with examples

## License

MIT License - see [LICENSE](LICENSE) file for details. 