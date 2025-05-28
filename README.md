# FFmpeg for Apple Silicon

Automated static FFmpeg build with full codec support and hardware acceleration for Apple Silicon (ARM64).

## 🚀 Features

- **Static Build** - no dependencies, works everywhere
- **Hardware Acceleration** - VideoToolbox, AudioToolbox, Metal
- **Full Codec Support** - all popular video/audio formats
- **Automated Build** via GitHub Actions
- **ARM64 Optimized** - maximum performance on Apple Silicon
- **Motion Vector Export** - modern runtime API support
- **Quick Testing** - validate changes in 5-10 minutes

## 📦 Included Libraries

### Video Codecs
- **x264** - H.264 encoding (AVC)
- **x265** - H.265 encoding (HEVC) with 10/12-bit support
- **libvpx** - VP8/VP9 encoding with high bit depth
- **libaom** - AV1 encoding/decoding
- **SVT-AV1** - fast AV1 encoder from Intel
- **kvazaar** - HEVC encoder

### Audio Codecs
- **libmp3lame** - MP3 encoding
- **libopus** - Opus codec
- **libvorbis** - Vorbis codec
- **libflac** - FLAC lossless audio

### Images and Subtitles
- **libwebp** - WebP images
- **libopenjpeg** - JPEG 2000
- **libass** - Advanced SubStation Alpha subtitles
- **libfreetype** - TrueType font rendering
- **fontconfig** - Font configuration
- **harfbuzz** - Text shaping
- **fribidi** - Unicode bidirectional text

### Filters and Processing
- **vid.stab** - Video stabilization
- **zimg** - Image scaling and colorspace conversion

### Containers
- **libbluray** - Blu-ray disc support

## 🛠 Build Options

### 🐳 Docker Build (Recommended)

**Easy codec modification** - edit only `scripts/configure-ffmpeg.sh`!

```bash
# Build locally
docker build -t ffmpeg-custom .

# Extract binaries
docker run --rm -v $(pwd):/output \
  -e COPY_BINARIES=true -e OUTPUT_DIR=/output \
  ffmpeg-custom

# Or use directly
docker run --rm -v $(pwd):/workspace ffmpeg-custom \
  ffmpeg -i /workspace/input.mp4 /workspace/output.mp4
```

**Adding new codecs:**
1. Edit `scripts/configure-ffmpeg.sh` (add `--enable-libnewcodec`)
2. Add dependencies to `Dockerfile` and `build-dependencies.sh` if needed
3. Commit and push - automatic rebuild!

### ⚡ Quick Testing (5-10 minutes)

Test your configuration changes without waiting 2+ hours:

```bash
# Local quick test
./test-build.sh

# Docker quick test
docker build -f Dockerfile.test -t ffmpeg-test .

# GitHub Actions quick test
# Automatically triggered on config changes
```

### 📱 Native macOS Build

**Full hardware acceleration support**

```bash
# Automatic build via GitHub Actions
# 1. Fork this repository
# 2. Go to Actions tab
# 3. Run "Build FFmpeg for Apple Silicon" workflow
# 4. Download binaries from Artifacts or Releases

# Manual local build (requires macOS with Apple Silicon)
git clone https://github.com/yourusername/ffmpeg-apple-silicon.git
cd ffmpeg-apple-silicon
./scripts/build.sh
```

## 📥 Using Pre-built Binaries

### Download Latest Release

Artifacts are automatically created for each release and available in multiple formats:

**📦 Static Binaries (Recommended)**
```bash
# Download latest release
curl -s https://api.github.com/repos/yourusername/ffmpeg-apple-silicon/releases/latest | \
  grep "browser_download_url.*tar.gz" | cut -d '"' -f 4 | wget -qi -

# Extract
tar -xzf ffmpeg-apple-silicon-*.tar.gz

# Remove from quarantine (macOS)
xattr -dr com.apple.quarantine ffmpeg ffprobe ffplay
codesign -s - ffmpeg ffprobe ffplay

# Test
./ffmpeg -version
```

**🐳 Docker Image**
```bash
# Pull latest image
docker pull ghcr.io/yourusername/ffmpeg-apple-silicon/ffmpeg:latest

# Use directly
docker run --rm -v $(pwd):/workspace ghcr.io/yourusername/ffmpeg-apple-silicon/ffmpeg:latest \
  ffmpeg -i /workspace/input.mp4 /workspace/output.mp4

# Extract binaries
docker run --rm -v $(pwd):/output ghcr.io/yourusername/ffmpeg-apple-silicon/ffmpeg:latest \
  sh -c "cp /opt/ffmpeg/bin/* /output/"
```

### Manual Release Creation

**For Maintainers:**
```bash
# Create new release (automatic versioning)
./create-release.sh

# Create with custom version
./create-release.sh v2024.01.15

# Test release build locally
./test-release.sh
```

## 🎬 Usage Examples

### Basic Conversion
```bash
./ffmpeg -i input.mp4 output.avi
```

### Hardware Acceleration (VideoToolbox)
```bash
# H.264 with hardware acceleration
./ffmpeg -hwaccel videotoolbox -i input.mp4 -c:v h264_videotoolbox -b:v 5M output.mp4

# H.265 with hardware acceleration  
./ffmpeg -hwaccel videotoolbox -i input.mp4 -c:v hevc_videotoolbox -b:v 3M output.mp4
```

### Modern Codecs
```bash
# AV1 encoding
./ffmpeg -i input.mp4 -c:v libaom-av1 -crf 30 output.webm

# VP9 encoding
./ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 30 output.webm

# H.265 10-bit
./ffmpeg -i input.mp4 -c:v libx265 -pix_fmt yuv420p10le -crf 28 output.mp4
```

### Motion Vector Export
```bash
# Export motion vectors with H.264
./ffmpeg -i input.mp4 -c:v libx264 -flags +mv output.mp4

# Extract motion vectors to file
./ffmpeg -flags +mv -i input.mp4 -vf codecview=mv=pf+bf+bb output.mp4
```

### Audio Processing
```bash
# MP3 encoding
./ffmpeg -i input.wav -c:a libmp3lame -b:a 320k output.mp3

# Opus encoding
./ffmpeg -i input.wav -c:a libopus -b:a 128k output.opus

# FLAC lossless
./ffmpeg -i input.wav -c:a flac output.flac
```

### Video Stabilization
```bash
# Analyze video
./ffmpeg -i input.mp4 -vf vidstabdetect=stepsize=6:shakiness=8:accuracy=9:result=transforms.trf -f null -

# Stabilize
./ffmpeg -i input.mp4 -vf vidstabtransform=input=transforms.trf:zoom=5:smoothing=10 output.mp4
```

### Subtitle Handling
```bash
# Burn-in subtitles
./ffmpeg -i input.mp4 -vf "ass=subtitles.ass" output.mp4

# Extract subtitles
./ffmpeg -i input.mkv -map 0:s:0 -c:s srt output.srt
```

## 🔧 Available Encoders

Check available encoders:
```bash
./ffmpeg -encoders
```

Main hardware encoders:
- `h264_videotoolbox` - H.264 with VideoToolbox
- `hevc_videotoolbox` - H.265 with VideoToolbox  
- `prores_videotoolbox` - ProRes with VideoToolbox

## 📊 Performance

On Apple Silicon M1/M2/M3:
- **VideoToolbox encoders** - up to 10x faster than software
- **x264/x265** - optimized for ARM64 with NEON
- **AV1** - next-generation codec support
- **Quick test builds** - 5-10 minutes vs 2+ hours

## 🐛 Troubleshooting

### Error "cannot be opened because the developer cannot be verified"
```bash
sudo xattr -rd com.apple.quarantine ffmpeg
sudo codesign --force --deep --sign - ffmpeg
```

### Library Issues
This build is fully static and should not require additional libraries. If problems occur:
```bash
# Check architecture
file ffmpeg
# Should show: Mach-O 64-bit executable arm64

# Check dependencies
otool -L ffmpeg
# Should show only system libraries
```

### Performance Issues
```bash
# Check available hardware accelerators
./ffmpeg -hwaccels

# Make sure you're using VideoToolbox
./ffmpeg -hwaccel videotoolbox -i input.mp4 -c:v h264_videotoolbox output.mp4
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `./test-build.sh` (quick validation)
5. Submit a pull request

### Adding New Codecs

#### Docker Build (Easy)
Edit `scripts/configure-ffmpeg.sh` and add your codec flag:
```bash
--enable-libnewcodec \
```

#### Native Build
1. Add source download in `build-ffmpeg.yml`
2. Add build step for the library
3. Add `--enable-libnewcodec` to FFmpeg configure

## 📄 License

This project is licensed under the GPL v3 License - see the [LICENSE](LICENSE) file for details.

FFmpeg is licensed under LGPL v2.1+ or GPL v2+, depending on configuration.

## 🙏 Acknowledgments

- FFmpeg team for the amazing multimedia framework
- All codec library maintainers
- GitHub Actions for free CI/CD
- Open source community

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