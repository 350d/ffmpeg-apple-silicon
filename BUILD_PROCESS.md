# FFmpeg Build Process for Apple Silicon

This document describes the technical build process for creating optimized FFmpeg binaries on Apple Silicon.

## Build Architecture

### Docker Multi-stage Build
- **Base image**: Ubuntu 22.04 ARM64
- **Build tools**: GCC, Clang, NASM, CMake
- **Target**: Static binaries with hardware acceleration

### Optimization Strategy

1. **ARM64 Native Compilation**
   - All libraries compiled with ARM64 optimizations
   - NEON instructions enabled where available
   - Apple Silicon specific flags

2. **Static Linking**
   - No external dependencies
   - Portable across different ARM64 systems
   - All codecs embedded

3. **Hardware Acceleration**
   - VideoToolbox integration
   - AudioToolbox support
   - Metal framework access

## Configuration Flags

### Core Build Options
```bash
--prefix=/opt/ffmpeg          # Installation path
--enable-static               # Static linking
--disable-shared              # No shared libraries
--enable-pic                  # Position independent code (essential for ARM64)
--arch=arm64                  # Target architecture
--cc=clang                    # Compiler selection
```

### License and Features
```bash
--enable-gpl                  # GPL license
--enable-version3             # GPL v3 support
--enable-nonfree              # Non-free codecs
--enable-avfilter             # Advanced filters
--enable-postproc             # Post-processing
--enable-pthreads             # Multi-threading
--enable-runtime-cpudetect    # CPU detection
```

### Apple Silicon Hardware Acceleration
```bash
--enable-videotoolbox         # Hardware video encoding/decoding
--enable-audiotoolbox         # Hardware audio processing
--enable-coreimage            # Image processing
--enable-appkit               # AppKit integration
--enable-avfoundation         # AV Foundation
--enable-metal                # Metal GPU acceleration
```

### Video Codecs
```bash
--enable-libx264              # H.264 encoding
--enable-libx265              # H.265/HEVC encoding
--enable-libvpx               # VP8/VP9 encoding
--enable-libaom               # AV1 codec
--enable-libsvtav1            # SVT-AV1 encoder
--enable-libkvazaar           # HEVC encoder
```

### Audio Codecs
```bash
--enable-libmp3lame           # MP3 encoding
--enable-libopus              # Opus codec
--enable-libvorbis            # Vorbis codec
--enable-libflac              # FLAC lossless
```

### Text and Subtitle Support
```bash
--enable-libass               # Advanced SubStation Alpha
--enable-libfreetype          # Font rendering
--enable-libfontconfig        # Font configuration
--enable-libfribidi           # Bidirectional text
--enable-libharfbuzz          # Text shaping
```

### Image and Container Support
```bash
--enable-libwebp              # WebP images
--enable-libopenjpeg          # JPEG 2000
--enable-libbluray            # Blu-ray discs
```

### Video Processing
```bash
--enable-libvidstab           # Video stabilization
--enable-libzimg              # Advanced scaling
```

## Motion Vector Support

**Important**: Motion vectors are now accessed via runtime parameters, not configure flags.

### Modern Motion Vector Access
```bash
# Runtime export (replaces old --enable-mv-export)
ffmpeg -flags2 +export_mvs -i input.mp4 [options]

# Visualization
ffmpeg -flags2 +export_mvs -i input.mp4 -vf codecview=mv=pf output.mp4
```

### Programmatic Access
```c
// Enable motion vector export
AVDictionary *opts = NULL;
av_dict_set(&opts, "flags2", "+export_mvs", 0);
avcodec_open2(codec_ctx, codec, &opts);

// Access motion vector data
AVFrameSideData *sd = av_frame_get_side_data(frame, AV_FRAME_DATA_MOTION_VECTORS);
```

## Build Dependencies

### System Libraries
- zlib (compression)
- libiconv (character encoding)
- SDL2 (for ffplay)

### External Codec Libraries
- x264 (H.264)
- x265 (H.265)
- libvpx (VP8/VP9)
- AOM (AV1)
- SVT-AV1 (Intel AV1)
- kvazaar (HEVC)

### Audio Libraries
- LAME (MP3)
- Opus
- Vorbis
- OGG
- FLAC

### Text/Graphics Libraries
- FreeType (fonts)
- FontConfig (font management)
- FriBidi (bidirectional text)
- HarfBuzz (text shaping)
- libass (subtitles)
- libwebp (images)
- OpenJPEG (JPEG 2000)

### Processing Libraries
- vid.stab (stabilization)
- zimg (scaling)

## Build Process Steps

### 1. Environment Setup
```bash
export FFMPEG_BUILD_ROOT=/opt/ffmpeg
export SOURCE_DIR=/opt/ffmpeg/source
export BIN_DIR=/opt/ffmpeg/bin
export PKG_CONFIG_PATH=/opt/ffmpeg/lib/pkgconfig
```

### 2. Dependency Compilation
Each library is built with:
- Static linking enabled
- Shared libraries disabled
- ARM64 optimizations
- Position independent code (--enable-pic)

### 3. FFmpeg Configuration
The main FFmpeg configure step uses all built dependencies and applies Apple Silicon specific optimizations.

### 4. Compilation
- Multi-threaded build using all available cores
- ARM64 assembly optimizations
- NEON instruction usage where beneficial

### 5. Binary Packaging
- Strip symbols for size reduction
- Package with metadata
- Create distributable archive

## Performance Optimizations

### ARM64 Specific
- NEON SIMD instructions
- ARM64 assembly routines
- Hardware crypto acceleration (where available)

### Apple Silicon Features
- Unified memory architecture awareness
- Performance/efficiency core scheduling
- Hardware video encoders/decoders

### Memory Management
- Static allocation where possible
- Minimized memory fragmentation
- Cache-friendly data structures

## Testing and Validation

### Quick Testing (5-10 minutes)
```bash
./test-build.sh
```
- Minimal x264-only build
- Basic functionality tests
- Motion vector export validation
- Configuration verification

### Full Testing (2+ hours)
```bash
docker build .
```
- Complete codec suite
- Hardware acceleration tests
- Comprehensive format support
- Performance benchmarks

## Troubleshooting

### Common Build Issues

**Library not found**
- Ensure PKG_CONFIG_PATH is set correctly
- Check library was built successfully
- Verify static library (.a) exists

**Architecture mismatch**
- Confirm --arch=arm64 in all configurations
- Check compiler target architecture
- Validate cross-compilation settings

**Motion vector issues**
- Use runtime flags, not configure flags
- Check codec supports motion vector export
- Verify frame type (P/B frames needed)

### Performance Issues

**Slow encoding**
- Verify hardware acceleration enabled
- Check VideoToolbox availability
- Monitor CPU/GPU usage

**Memory usage**
- Use appropriate preset settings
- Monitor memory allocation
- Check for memory leaks

## Maintenance

### Updating Dependencies
1. Update version numbers in Dockerfile
2. Test with quick build first
3. Update documentation
4. Full build and test

### Adding New Codecs
1. Add dependency build in `build-dependencies.sh`
2. Add configure flag in `configure-ffmpeg.sh`
3. Update documentation
4. Test with quick build

### Version Management
- Tag releases with semantic versioning
- Maintain changelog
- Test across different macOS versions
- Validate hardware acceleration on different Apple Silicon variants 