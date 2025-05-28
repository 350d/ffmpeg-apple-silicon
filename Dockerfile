# Stage 1: Build dependencies (cacheable)
FROM --platform=linux/arm64 ubuntu:22.04 AS dependencies

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Suppress all compiler warnings and build noise
ENV CFLAGS="-w -O2"
ENV CXXFLAGS="-w -O2"
ENV CPPFLAGS="-w"
ENV LDFLAGS="-w"

# Set build environment
ENV FFMPEG_BUILD_ROOT=/opt/ffmpeg
ENV SOURCE_DIR=/opt/ffmpeg/source
ENV PKG_CONFIG_PATH=/opt/ffmpeg/lib/pkgconfig

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    cmake \
    ninja-build \
    nasm \
    yasm \
    pkg-config \
    autoconf \
    automake \
    libtool \
    meson \
    python3 \
    python3-pip \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create build directories
RUN mkdir -p "$FFMPEG_BUILD_ROOT" "$SOURCE_DIR"

# Download and build dependencies script
COPY scripts/build-dependencies.sh /scripts/
RUN chmod +x /scripts/build-dependencies.sh

# Download and extract source packages
WORKDIR $SOURCE_DIR

# Core libraries (cacheable layer)
RUN curl -L "https://github.com/madler/zlib/archive/refs/tags/v1.3.tar.gz" -o zlib.tar.gz && \
    curl -L "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.17.tar.gz" -o libiconv.tar.gz && \
    tar -xzf zlib.tar.gz && rm zlib.tar.gz && \
    tar -xzf libiconv.tar.gz && rm libiconv.tar.gz

# Audio codecs (cacheable layer)
RUN curl -L "https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz" -o lame.tar.gz && \
    curl -L "https://archive.mozilla.org/pub/opus/opus-1.4.tar.gz" -o opus.tar.gz && \
    curl -L "https://downloads.xiph.org/releases/ogg/libogg-1.3.5.tar.gz" -o libogg.tar.gz && \
    curl -L "https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.gz" -o libvorbis.tar.gz && \
    curl -L "https://downloads.xiph.org/releases/flac/flac-1.4.3.tar.xz" -o flac.tar.xz && \
    tar -xzf lame.tar.gz && rm lame.tar.gz && \
    tar -xzf opus.tar.gz && rm opus.tar.gz && \
    tar -xzf libogg.tar.gz && rm libogg.tar.gz && \
    tar -xzf libvorbis.tar.gz && rm libvorbis.tar.gz && \
    tar -xJf flac.tar.xz && rm flac.tar.xz

# Video codecs (cacheable layer)
RUN git clone --depth 1 https://code.videolan.org/videolan/x264.git && \
    curl -L "https://bitbucket.org/multicoreware/x265/downloads/x265_3.5.tar.gz" -o x265.tar.gz && \
    tar -xzf x265.tar.gz && rm x265.tar.gz && \
    git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git && \
    git clone --depth 1 https://aomedia.googlesource.com/aom.git && \
    git clone --depth 1 https://github.com/ultravideo/kvazaar.git && \
    git clone --depth 1 https://gitlab.com/AOMediaCodec/SVT-AV1.git

# Image formats (cacheable layer)
RUN curl -L "https://github.com/webmproject/libwebp/archive/refs/tags/v1.3.2.tar.gz" -o libwebp.tar.gz && \
    curl -L "https://github.com/uclouvain/openjpeg/archive/refs/tags/v2.5.0.tar.gz" -o openjpeg.tar.gz && \
    tar -xzf libwebp.tar.gz && rm libwebp.tar.gz && \
    tar -xzf openjpeg.tar.gz && rm openjpeg.tar.gz

# Text rendering (cacheable layer)
RUN curl -L "https://download.savannah.gnu.org/releases/freetype/freetype-2.13.2.tar.xz" -o freetype.tar.xz && \
    curl -L "https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.14.2.tar.xz" -o fontconfig.tar.xz && \
    curl -L "https://github.com/fribidi/fribidi/releases/download/v1.0.13/fribidi-1.0.13.tar.xz" -o fribidi.tar.xz && \
    curl -L "https://github.com/harfbuzz/harfbuzz/releases/download/8.3.0/harfbuzz-8.3.0.tar.xz" -o harfbuzz.tar.xz && \
    curl -L "https://github.com/libass/libass/releases/download/0.17.1/libass-0.17.1.tar.xz" -o libass.tar.xz && \
    tar -xJf freetype.tar.xz && rm freetype.tar.xz && \
    tar -xJf fontconfig.tar.xz && rm fontconfig.tar.xz && \
    tar -xJf fribidi.tar.xz && rm fribidi.tar.xz && \
    tar -xJf harfbuzz.tar.xz && rm harfbuzz.tar.xz && \
    tar -xJf libass.tar.xz && rm libass.tar.xz

# Video processing (cacheable layer)
RUN git clone --depth 1 https://github.com/georgmartius/vid.stab.git && \
    curl -L "https://github.com/sekrit-twc/zimg/archive/refs/tags/release-3.0.5.tar.gz" -o zimg.tar.gz && \
    tar -xzf zimg.tar.gz && rm zimg.tar.gz

# Container formats (cacheable layer)
RUN git clone --depth 1 https://code.videolan.org/videolan/libbluray.git

# SDL for ffplay (cacheable layer)
RUN curl -L "https://github.com/libsdl-org/SDL/releases/download/release-2.28.5/SDL2-2.28.5.tar.gz" -o sdl2.tar.gz && \
    tar -xzf sdl2.tar.gz && rm sdl2.tar.gz

# Build all dependencies (heavy cacheable layer)
RUN /scripts/build-dependencies.sh

# Stage 2: FFmpeg build (uses cached dependencies)
FROM dependencies AS ffmpeg-builder

# Continue suppressing warnings
ENV CFLAGS="-w -O2"
ENV CXXFLAGS="-w -O2"
ENV CPPFLAGS="-w"
ENV LDFLAGS="-w"

ENV BIN_DIR=/opt/ffmpeg/bin
ENV PATH="/opt/ffmpeg/bin:$PATH"
ENV MACOSX_DEPLOYMENT_TARGET=11.0

# Create bin directory
RUN mkdir -p "$BIN_DIR"

# Download FFmpeg (this layer changes with FFmpeg updates)
ARG FFMPEG_VERSION=master
WORKDIR $SOURCE_DIR
RUN if [ "$FFMPEG_VERSION" = "master" ]; then \
        git clone --depth 1 https://git.ffmpeg.org/ffmpeg.git; \
    else \
        git clone https://git.ffmpeg.org/ffmpeg.git && \
        cd ffmpeg && \
        git checkout "$FFMPEG_VERSION"; \
    fi

# Copy FFmpeg configuration script
COPY scripts/configure-ffmpeg.sh /scripts/
COPY scripts/show-progress.sh /scripts/
RUN chmod +x /scripts/configure-ffmpeg.sh /scripts/show-progress.sh

# Build FFmpeg (only this layer rebuilds when config changes)
WORKDIR $SOURCE_DIR/ffmpeg
RUN /scripts/configure-ffmpeg.sh

# Stage 3: Final runtime image
FROM --platform=linux/arm64 ubuntu:22.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy built binaries from builder stage
COPY --from=ffmpeg-builder /opt/ffmpeg/bin /opt/ffmpeg/bin

# Set up environment
ENV PATH="/opt/ffmpeg/bin:$PATH"

# Strip binaries to reduce size
RUN strip /opt/ffmpeg/bin/ffmpeg /opt/ffmpeg/bin/ffprobe /opt/ffmpeg/bin/ffplay

# Create package info
WORKDIR /opt/ffmpeg/bin
RUN cat > ffmpeg-info.txt << EOF && \
    echo "FFmpeg static build for ARM64" && \
    echo "Build date: $(date)" && \
    echo "FFmpeg version: $(/opt/ffmpeg/bin/ffmpeg -version | head -n1)" && \
    echo "" && \
    echo "Included libraries:" && \
    echo "- x264, x265 (H.264/H.265 encoding)" && \
    echo "- libvpx (VP8/VP9)" && \
    echo "- libaom (AV1)" && \
    echo "- SVT-AV1 (AV1 encoding)" && \
    echo "- libass (subtitle rendering)" && \
    echo "- libfreetype, fontconfig (text rendering)" && \
    echo "- libmp3lame (MP3 encoding)" && \
    echo "- libopus (Opus audio)" && \
    echo "- libvorbis (Vorbis audio)" && \
    echo "- libwebp (WebP images)" && \
    echo "- vid.stab (video stabilization)" && \
    echo "- And many more..." \
EOF

RUN tar -czf ffmpeg-arm64-$(date +%Y%m%d).tar.gz ffmpeg ffprobe ffplay ffmpeg-info.txt

# Test the build
RUN /opt/ffmpeg/bin/ffmpeg -version && \
    /opt/ffmpeg/bin/ffprobe -version && \
    /opt/ffmpeg/bin/ffplay -version

# Set up entrypoint
COPY scripts/docker-entrypoint.sh /scripts/
RUN chmod +x /scripts/docker-entrypoint.sh

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
CMD ["ffmpeg"] 