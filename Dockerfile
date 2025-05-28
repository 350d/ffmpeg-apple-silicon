# FFmpeg Apple Silicon Build Container
FROM --platform=linux/arm64 ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Set build environment
ENV FFMPEG_BUILD_ROOT=/opt/ffmpeg
ENV SOURCE_DIR=/opt/ffmpeg/source
ENV BIN_DIR=/opt/ffmpeg/bin
ENV PKG_CONFIG_PATH=/opt/ffmpeg/lib/pkgconfig
ENV PATH="/opt/ffmpeg/bin:$PATH"
ENV MACOSX_DEPLOYMENT_TARGET=11.0

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
RUN mkdir -p "$FFMPEG_BUILD_ROOT" "$SOURCE_DIR" "$BIN_DIR"

# Download and build dependencies script
COPY scripts/build-dependencies.sh /scripts/
RUN chmod +x /scripts/build-dependencies.sh

# Download and extract source packages
WORKDIR $SOURCE_DIR

# Core libraries
RUN curl -L "https://github.com/madler/zlib/archive/refs/tags/v1.3.tar.gz" -o zlib.tar.gz && \
    curl -L "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.17.tar.gz" -o libiconv.tar.gz

# Audio codecs  
RUN curl -L "https://downloads.sourceforge.net/lame/lame-3.100.tar.gz" -o lame.tar.gz && \
    curl -L "https://archive.mozilla.org/pub/opus/opus-1.4.tar.gz" -o opus.tar.gz && \
    curl -L "https://downloads.xiph.org/releases/ogg/libogg-1.3.5.tar.gz" -o libogg.tar.gz && \
    curl -L "https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.gz" -o libvorbis.tar.gz && \
    curl -L "https://downloads.xiph.org/releases/flac/flac-1.4.3.tar.xz" -o flac.tar.xz

# Video codecs
RUN git clone --depth 1 https://code.videolan.org/videolan/x264.git && \
    curl -L "https://bitbucket.org/multicoreware/x265/downloads/x265_3.5.tar.gz" -o x265.tar.gz && \
    git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git && \
    git clone --depth 1 https://aomedia.googlesource.com/aom.git && \
    git clone --depth 1 https://github.com/ultravideo/kvazaar.git && \
    git clone --depth 1 https://gitlab.com/AOMediaCodec/SVT-AV1.git

# Image formats
RUN curl -L "https://github.com/webmproject/libwebp/archive/refs/tags/v1.3.2.tar.gz" -o libwebp.tar.gz && \
    curl -L "https://github.com/uclouvain/openjpeg/archive/refs/tags/v2.5.0.tar.gz" -o openjpeg.tar.gz

# Text rendering
RUN curl -L "https://download.savannah.gnu.org/releases/freetype/freetype-2.13.2.tar.xz" -o freetype.tar.xz && \
    curl -L "https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.14.2.tar.xz" -o fontconfig.tar.xz && \
    curl -L "https://github.com/fribidi/fribidi/releases/download/v1.0.13/fribidi-1.0.13.tar.xz" -o fribidi.tar.xz && \
    curl -L "https://github.com/harfbuzz/harfbuzz/releases/download/8.3.0/harfbuzz-8.3.0.tar.xz" -o harfbuzz.tar.xz && \
    curl -L "https://github.com/libass/libass/releases/download/0.17.1/libass-0.17.1.tar.xz" -o libass.tar.xz

# Video processing
RUN git clone --depth 1 https://github.com/georgmartius/vid.stab.git && \
    curl -L "https://github.com/sekrit-twc/zimg/archive/refs/tags/release-3.0.5.tar.gz" -o zimg.tar.gz

# Container formats
RUN git clone --depth 1 https://code.videolan.org/videolan/libbluray.git

# SDL for ffplay (Linux alternative)
RUN curl -L "https://github.com/libsdl-org/SDL/releases/download/release-2.28.5/SDL2-2.28.5.tar.gz" -o sdl2.tar.gz

# Extract archives (improved extraction)
RUN set -x && \
    for file in *.tar.gz; do \
        if [ -f "$file" ]; then \
            echo "Extracting $file..."; \
            tar -xzf "$file" && rm "$file"; \
        fi; \
    done && \
    for file in *.tar.xz; do \
        if [ -f "$file" ]; then \
            echo "Extracting $file..."; \
            tar -xJf "$file" && rm "$file"; \
        fi; \
    done && \
    echo "Extracted directories:"; \
    ls -la

# Build all dependencies
RUN /scripts/build-dependencies.sh

# Download FFmpeg
ARG FFMPEG_VERSION=master
RUN if [ "$FFMPEG_VERSION" = "master" ]; then \
        git clone --depth 1 https://git.ffmpeg.org/ffmpeg.git; \
    else \
        git clone https://git.ffmpeg.org/ffmpeg.git && \
        cd ffmpeg && \
        git checkout "$FFMPEG_VERSION"; \
    fi

# Copy FFmpeg configuration script
COPY scripts/configure-ffmpeg.sh /scripts/
RUN chmod +x /scripts/configure-ffmpeg.sh

# Build FFmpeg
WORKDIR $SOURCE_DIR/ffmpeg
RUN /scripts/configure-ffmpeg.sh && \
    make -j$(nproc) && \
    make install

# Strip binaries to reduce size
RUN strip "$BIN_DIR/ffmpeg" "$BIN_DIR/ffprobe" "$BIN_DIR/ffplay"

# Create package
WORKDIR $BIN_DIR
RUN cat > ffmpeg-info.txt << EOF && \
    FFmpeg static build for ARM64 \
    Build date: $(date) \
    FFmpeg version: $($BIN_DIR/ffmpeg -version | head -n1) \
    \
    Included libraries: \
    - x264, x265 (H.264/H.265 encoding) \
    - libvpx (VP8/VP9) \
    - libaom (AV1) \
    - SVT-AV1 (AV1 encoding) \
    - libass (subtitle rendering) \
    - libfreetype, fontconfig (text rendering) \
    - libmp3lame (MP3 encoding) \
    - libopus (Opus audio) \
    - libvorbis (Vorbis audio) \
    - libwebp (WebP images) \
    - vid.stab (video stabilization) \
    - And many more... \
EOF

RUN tar -czf ffmpeg-arm64-$(date +%Y%m%d).tar.gz ffmpeg ffprobe ffplay ffmpeg-info.txt

# Test the build
RUN "$BIN_DIR/ffmpeg" -version && \
    "$BIN_DIR/ffprobe" -version && \
    "$BIN_DIR/ffplay" -version

# Set up entrypoint
COPY scripts/docker-entrypoint.sh /scripts/
RUN chmod +x /scripts/docker-entrypoint.sh

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
CMD ["ffmpeg"] 