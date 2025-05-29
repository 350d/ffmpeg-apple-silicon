FROM --platform=linux/arm64 ubuntu:22.04 AS base

# Install minimal build tools
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    pkg-config \
    autoconf \
    automake \
    libtool \
    nasm \
    yasm \
    && rm -rf /var/lib/apt/lists/*

ENV FFMPEG_BUILD_ROOT="/opt/ffmpeg"
ENV PKG_CONFIG_PATH="$FFMPEG_BUILD_ROOT/lib/pkgconfig"
ENV PATH="$FFMPEG_BUILD_ROOT/bin:$PATH"
RUN mkdir -p "$FFMPEG_BUILD_ROOT" /tmp/build

# Build only fastest essential codecs 
WORKDIR /tmp/build
RUN echo "🚀 Building fast essential codecs (x264, lame)..." \
    # x264 (H.264 encoder) - fastest codec to build
    && git clone --depth 1 https://code.videolan.org/videolan/x264.git x264 \
    && cd x264 \
    && ./configure --prefix="$FFMPEG_BUILD_ROOT" --disable-shared --enable-static --enable-pic \
    && make -j$(nproc) \
    && make install \
    && cd .. && rm -rf x264 \
    && echo "✅ x264 completed" \
    # libmp3lame (MP3 encoder) - small and fast
    && curl -L "https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz" -o lame.tar.gz \
    && tar -xzf lame.tar.gz && rm lame.tar.gz \
    && cd lame-3.100 \
    && ./configure --prefix="$FFMPEG_BUILD_ROOT" --disable-shared --enable-static \
    && make -j$(nproc) \
    && make install \
    && cd .. && rm -rf lame-3.100 \
    && echo "✅ lame completed"

# Build FFmpeg with minimal configuration
COPY scripts/build-ffmpeg.sh /scripts/
RUN chmod +x /scripts/build-ffmpeg.sh && /scripts/build-ffmpeg.sh

# Final stage
FROM --platform=linux/arm64 ubuntu:22.04 AS final
RUN apt-get update && apt-get install -y libgomp1 && rm -rf /var/lib/apt/lists/*
COPY --from=base /opt/ffmpeg/bin/* /usr/local/bin/

# Verify installation
RUN ffmpeg -version

WORKDIR /workspace
ENTRYPOINT ["ffmpeg"] 