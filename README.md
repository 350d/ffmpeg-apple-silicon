# FFmpeg Apple Silicon Builder 🚀

Fast, efficient FFmpeg builds optimized for Apple Silicon (ARM64) architecture using Docker.

## 🎯 Features

- **⚡ Ultra-Fast Builds**: 6-10 minutes vs 2+ hours previously  
- **🔧 Essential Codecs**: H.264 (x264) and MP3 (lame) support
- **🏗️ ARM64 Optimized**: Native Apple Silicon performance
- **🐳 Docker-Based**: Consistent builds across platforms
- **🔄 GitHub Actions**: Automated CI/CD pipeline

## 🚀 Quick Start

### Using Pre-built Docker Image
```bash
# Pull the latest image
docker pull ghcr.io/yourusername/ffmpeg-apple-silicon:latest

# Convert video to H.264
docker run --rm -v $(pwd):/workspace ffmpeg-apple-silicon:latest \
  -i input.mov -c:v libx264 -c:a libmp3lame output.mp4
```

### Building Locally
```bash
git clone https://github.com/yourusername/ffmpeg-apple-silicon.git
cd ffmpeg-apple-silicon
docker build -t ffmpeg-fast .
```

## 📊 Performance

| Version | Build Time | Codecs | Use Case |
|---------|------------|---------|-----------|
| v2.1.0 | 6-10 min | H.264, MP3 | ⚡ Fast development |
| v2.0.x | 45+ min | H.264, H.265, VP9, AV1, Opus, MP3 | 🔧 Full features |
| v1.x | 2+ hours | All codecs | 📦 Stable releases |

## 🔧 Supported Codecs

### Video
- **H.264 (x264)**: Industry standard, fast encoding
- **Hardware acceleration**: V4L2 support for ARM64

### Audio  
- **MP3 (lame)**: Universal compatibility
- **Native formats**: PCM, AAC (built-in)

## 📝 Usage Examples

### Basic Video Conversion
```bash
docker run --rm -v $(pwd):/workspace ffmpeg-fast:latest \
  -i input.mp4 -c:v libx264 -crf 23 -c:a libmp3lame output.mp4
```

### Batch Processing
```bash
for file in *.mov; do
  docker run --rm -v $(pwd):/workspace ffmpeg-fast:latest \
    -i "$file" -c:v libx264 -c:a libmp3lame "${file%.*}.mp4"
done
```

### Streaming Optimization
```bash
docker run --rm -v $(pwd):/workspace ffmpeg-fast:latest \
  -i input.mp4 -c:v libx264 -preset fast -tune zerolatency \
  -c:a libmp3lame -b:a 128k output.mp4
```

## 🏗️ Architecture

The v2.1.0 architecture focuses on speed and simplicity:

```
Base Ubuntu 22.04 ARM64
├── Essential build tools
├── x264 (H.264 encoder) 
├── lame (MP3 encoder)
└── FFmpeg (minimal config)
```

**Key Optimizations:**
- ⚡ Minimal dependency set
- 🎯 Only essential codecs
- 📦 Single-layer Docker build
- 🔧 Parallel compilation (`-j$(nproc)`)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/awesome-codec`
3. Make your changes
4. Test locally: `docker build -t test .`
5. Submit a pull request

## 📈 Version History

- **v2.1.0**: Fast minimal build (6-10 min) - H.264 + MP3
- **v2.0.1**: Multi-layer caching (45+ min) - Full codec support  
- **v1.1.2**: Stable releases (2+ hours) - Maximum compatibility

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [FFmpeg](https://ffmpeg.org/) - The complete multimedia solution
- [x264](https://www.videolan.org/developers/x264.html) - H.264 encoder
- [lame](http://lame.sourceforge.net/) - MP3 encoder
- Docker community for ARM64 support

## 📄 Documentation

- [Build Process Details](BUILD_PROCESS.md) - Technical build documentation
- [Motion Vectors Guide](MOTION_VECTORS.md) - Modern motion vector access

## 🔗 Links

- [FFmpeg Official Site](https://ffmpeg.org/)
- [VideoToolbox Documentation](https://developer.apple.com/documentation/videotoolbox)
- [Apple Silicon Optimization Guide](https://developer.apple.com/documentation/apple-silicon) 

## 🎯 Recent Improvements

### ✅ ARM64 Build Optimization
- **Added `--enable-pic`** to all configurations for correct static builds on Apple Silicon
- **Fixed Motion Vector support**: removed deprecated `--enable-mv-export`, added modern API documentation
- Improved compatibility with GPT recommendations for FFmpeg ARM64

### ✅ Motion Vectors - Important Update
**The `--enable-mv-export` flag is no longer supported!** 

Instead, use the modern runtime approach:
```bash
# Export motion vectors
ffmpeg -flags2 +export_mvs -i video.mp4 -vf codecview=mv=pf output.mp4

# Programmatic access via API (see MOTION_VECTORS.md)
av_dict_set(&opts, "flags2", "+export_mvs", 0);
```

📋 **Details**: See [MOTION_VECTORS.md](MOTION_VECTORS.md) for complete guide

### ✅ Quick Testing System
- **Build time**: 2.5 minutes (instead of 2+ hours)
- **Docker testing**: Minimal configuration with x264 only
- **Automated checks**: GitHub Actions + local scripts 