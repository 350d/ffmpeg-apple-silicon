ARG TARGETPLATFORM=linux/arm64

FROM --platform=$TARGETPLATFORM ubuntu:22.04 AS base

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
    && echo "✅ x264 completed" \
    # lame (MP3 encoder)
    && cd /tmp/build \
    && curl -L "https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz" -o lame.tar.gz \
    && tar -xzf lame.tar.gz \
    && cd lame-3.100 \
    && ./configure --prefix="$FFMPEG_BUILD_ROOT" --disable-shared --enable-static \
    && make -j$(nproc) \
    && make install \
    && echo "✅ lame completed" \
    && cd /tmp/build \
    && rm -rf x264 lame-3.100 lame.tar.gz

# Copy FFmpeg build script
COPY scripts/build-ffmpeg.sh /scripts/
RUN chmod +x /scripts/build-ffmpeg.sh

# Build FFmpeg
RUN /scripts/build-ffmpeg.sh

# Create final minimal image
FROM --platform=$TARGETPLATFORM ubuntu:22.04

# Copy only the built binaries and libraries
COPY --from=base /opt/ffmpeg/bin /opt/ffmpeg/bin
COPY --from=base /opt/ffmpeg/lib /opt/ffmpeg/lib

ENV PATH="/opt/ffmpeg/bin:$PATH"
ENV LD_LIBRARY_PATH="/opt/ffmpeg/lib:$LD_LIBRARY_PATH"

ENTRYPOINT ["ffmpeg"] 