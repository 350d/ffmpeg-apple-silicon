# FFmpeg Apple Silicon - Staged Build System

## 🏗️ **7-Stage Docker Build Architecture**

Система разбита на 7 этапов по **19 минут максимум** каждый для максимального кеширования.

### 📊 **Stage Overview**

| Stage | Target Time | Components | Output |
|-------|-------------|------------|---------|
| **Stage 1** | ~10min | Base System + Core Libraries | zlib, libiconv |
| **Stage 2** | ~18min | Audio Codecs | LAME, Opus, Vorbis, FLAC |
| **Stage 3** | ~19min | Video Codecs | x264, x265 |
| **Stage 4** | ~18min | Modern Video | VP8/VP9, AV1 |
| **Stage 5** | ~16min | Image Libraries | WebP, JPEG2000 |
| **Stage 6** | ~18min | Text Libraries | FreeType, FontConfig, ASS |
| **Stage 7** | ~18min | FFmpeg Final | Vid.stab, zimg, FFmpeg |

**🕒 Total Build Time:** ~117 minutes (1h 57m)

## 🚀 **Usage**

### **Build Individual Stages**
```bash
# Build up to Stage 3 (video codecs)
docker build --target stage3-video -t ffmpeg-stage3 -f Dockerfile.stage1 .

# Build complete system
docker build --target stage7-ffmpeg -t ffmpeg-complete -f Dockerfile.stage1 .
```

### **Test Specific Stage**
```bash
# Test audio stage
docker run --rm ffmpeg-stage2 

# Test final build
docker run --rm ffmpeg-complete ffmpeg -version
```

## 🔄 **Caching Strategy**

### **Docker Layer Caching**
```bash
# Enable BuildKit caching
export DOCKER_BUILDKIT=1

# Use cache mount
docker build --target stage7-ffmpeg \
  --cache-from type=local,src=/tmp/.buildx-cache \
  --cache-to type=local,dest=/tmp/.buildx-cache \
  -t ffmpeg-complete .
```

### **GitHub Actions Caching**
```yaml
- name: Build with cache
  uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
    target: stage7-ffmpeg
```

## 📈 **Performance Benefits**

### **Development Workflow**
- 🔧 **Config Changes:** Only rebuild Stage 7 (~18min vs 2h+)
- 🎵 **Audio Library Updates:** Rebuild from Stage 2 (~75min vs 2h+)
- 🎬 **Video Library Updates:** Rebuild from Stage 3 (~57min vs 2h+)

### **CI/CD Optimization**
- ⚡ **Incremental Builds:** Only changed stages rebuild
- 💾 **Reduced Storage:** Shared base layers across builds
- 🔄 **Parallel Development:** Multiple teams can work on different stages

## 🛠️ **Stage Details**

### **Stage 1: Foundation** (`Dockerfile.stage1`)
```dockerfile
FROM ubuntu:22.04 AS stage1-base
# System dependencies + zlib + libiconv
# Target: ~10 minutes
```

### **Stage 2: Audio** (`Dockerfile.stage2`)
```dockerfile
FROM stage1-base AS stage2-audio
# LAME, Opus, Vorbis, FLAC
# Target: ~18 minutes
```

### **Stage 3: Video** (`Dockerfile.stage3`)
```dockerfile
FROM stage2-audio AS stage3-video  
# x264, x265
# Target: ~19 minutes
```

### **Stage 4: Modern Video** (`Dockerfile.stage4`)
```dockerfile
FROM stage3-video AS stage4-modern
# libvpx, AOM (AV1)
# Target: ~18 minutes
```

### **Stage 5: Images** (`Dockerfile.stage5`)
```dockerfile
FROM stage4-modern AS stage5-image
# libwebp, OpenJPEG
# Target: ~16 minutes
```

### **Stage 6: Text** (`Dockerfile.stage6`)
```dockerfile
FROM stage5-image AS stage6-text
# FreeType, FontConfig, HarfBuzz, libass
# Target: ~18 minutes
```

### **Stage 7: Final** (`Dockerfile.stage7`)
```dockerfile
FROM stage6-text AS stage7-ffmpeg
# vid.stab, zimg, FFmpeg
# Target: ~18 minutes
```

## 🔍 **Monitoring**

Each stage creates markers with timestamps:
```bash
# Check stage completion
docker run --rm ffmpeg-stage3 cat /opt/ffmpeg/stage3.marker

# Output: stage3-complete-20240115-1430
```

## 🚨 **Troubleshooting**

### **Stage Failed?**
```bash
# Build only failed stage
docker build --target stage3-video -t debug-stage3 .

# Inspect the stage
docker run -it debug-stage3 bash
```

### **Cache Issues?**
```bash
# Clear Docker cache
docker builder prune -a

# Rebuild without cache
docker build --no-cache --target stage7-ffmpeg .
```

## 📝 **Notes**

- Each stage is **under 19 minutes** for GitHub Actions free tier
- **Docker layer caching** works automatically 
- **Incremental builds** save significant time
- **Parallel development** possible with stage isolation 