ARG TARGETPLATFORM=linux/arm64

FROM --platform=$TARGETPLATFORM ubuntu:22.04

# Install only essential build tools - no external dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    pkg-config \
    nasm \
    yasm \
    && rm -rf /var/lib/apt/lists/*

# Set up build environment
ENV FFMPEG_BUILD_ROOT="/opt/ffmpeg"
ENV PKG_CONFIG_PATH="$FFMPEG_BUILD_ROOT/lib/pkgconfig"
ENV PATH="$FFMPEG_BUILD_ROOT/bin:$PATH"
RUN mkdir -p "$FFMPEG_BUILD_ROOT"

# Download and build FFmpeg in one layer - no external codecs
WORKDIR /tmp
RUN echo "🚀 Building ultra-minimal FFmpeg (system codecs only)..." \
    && curl -L "https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2" -o ffmpeg.tar.bz2 \
    && tar -xjf ffmpeg.tar.bz2 \
    && rm ffmpeg.tar.bz2 \
    && cd ffmpeg \
    && ./configure \
        --prefix="$FFMPEG_BUILD_ROOT" \
        --disable-shared \
        --enable-static \
        --disable-debug \
        --disable-doc \
        --disable-ffplay \
        --disable-network \
        --disable-autodetect \
        --enable-encoder=libx264 \
        --enable-decoder=h264 \
        --enable-encoder=mp3 \
        --enable-decoder=mp3 \
        --enable-muxer=mp4 \
        --enable-demuxer=mp4 \
        --enable-muxer=mp3 \
        --enable-demuxer=mp3 \
        --enable-protocol=file \
    && make -j$(nproc) \
    && make install \
    && cd /tmp \
    && rm -rf ffmpeg \
    && echo "✅ Ultra-minimal FFmpeg completed"

# Test the build
RUN ffmpeg -version && echo "✅ FFmpeg working"

WORKDIR /workspace
ENTRYPOINT ["ffmpeg"] 