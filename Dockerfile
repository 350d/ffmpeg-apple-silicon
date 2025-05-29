FROM --platform=linux/arm64 ubuntu:22.04 AS base

# Install build tools once
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    pkg-config \
    autoconf \
    automake \
    libtool \
    nasm \
    yasm \
    python3 \
    python3-pip \
    meson \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

ENV FFMPEG_BUILD_ROOT="/opt/ffmpeg"
ENV PKG_CONFIG_PATH="$FFMPEG_BUILD_ROOT/lib/pkgconfig"
ENV PATH="$FFMPEG_BUILD_ROOT/bin:$PATH"
RUN mkdir -p "$FFMPEG_BUILD_ROOT"

# ================================================================
# INDIVIDUAL DEPENDENCY LAYERS (each gets cached separately)
# ================================================================

# Layer 1: x264 (H.264 encoder)
FROM base AS x264
RUN git clone --depth 1 https://code.videolan.org/videolan/x264.git /tmp/x264 \
    && cd /tmp/x264 \
    && ./configure --prefix="$FFMPEG_BUILD_ROOT" --disable-shared --enable-static --enable-pic \
    && make -j$(nproc) \
    && make install \
    && echo "✅ x264 completed"

# Layer 2: x265 (H.265 encoder)
FROM x264 AS x265
RUN git clone --depth 1 https://bitbucket.org/multicoreware/x265_git.git /tmp/x265 \
    && cd /tmp/x265/build/linux \
    && cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$FFMPEG_BUILD_ROOT" -DENABLE_SHARED=OFF ../../source \
    && make -j$(nproc) \
    && make install \
    && echo "✅ x265 completed"

# Layer 3: libvpx (VP8/VP9 encoder)
FROM x265 AS libvpx
RUN git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git /tmp/libvpx \
    && cd /tmp/libvpx \
    && ./configure --prefix="$FFMPEG_BUILD_ROOT" --disable-shared --enable-static --disable-examples --disable-tools --enable-vp9-highbitdepth \
    && make -j$(nproc) \
    && make install \
    && echo "✅ libvpx completed"

# Layer 4: AOM (AV1 encoder)
FROM libvpx AS aom
RUN git clone --depth 1 https://aomedia.googlesource.com/aom /tmp/aom \
    && cd /tmp/aom \
    && mkdir build && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX="$FFMPEG_BUILD_ROOT" -DBUILD_SHARED_LIBS=OFF -DENABLE_DOCS=OFF -DENABLE_TESTS=OFF .. \
    && make -j$(nproc) \
    && make install \
    && echo "✅ aom completed"

# Layer 5: SVT-AV1 (Intel AV1 encoder)
FROM aom AS svtav1
RUN git clone --depth 1 https://gitlab.com/AOMediaCodec/SVT-AV1.git /tmp/svt-av1 \
    && cd /tmp/svt-av1 \
    && mkdir build && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX="$FFMPEG_BUILD_ROOT" -DBUILD_SHARED_LIBS=OFF .. \
    && make -j$(nproc) \
    && make install \
    && echo "✅ svt-av1 completed"

# Layer 6: libmp3lame (MP3 encoder)
FROM svtav1 AS lame
RUN curl -L "https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz" -o lame.tar.gz \
    && tar -xzf lame.tar.gz && rm lame.tar.gz \
    && cd lame-3.100 \
    && ./configure --prefix="$FFMPEG_BUILD_ROOT" --disable-shared --enable-static \
    && make -j$(nproc) \
    && make install \
    && echo "✅ lame completed"

# Layer 7: opus (Opus encoder)
FROM lame AS opus
RUN git clone --depth 1 https://github.com/xiph/opus.git /tmp/opus \
    && cd /tmp/opus \
    && ./autogen.sh \
    && ./configure --prefix="$FFMPEG_BUILD_ROOT" --disable-shared --enable-static \
    && make -j$(nproc) \
    && make install \
    && echo "✅ opus completed"

# Layer 8: libvorbis (Vorbis encoder)
FROM opus AS vorbis
RUN git clone --depth 1 https://github.com/xiph/vorbis.git /tmp/vorbis \
    && cd /tmp/vorbis \
    && ./autogen.sh \
    && ./configure --prefix="$FFMPEG_BUILD_ROOT" --disable-shared --enable-static \
    && make -j$(nproc) \
    && make install \
    && echo "✅ vorbis completed"

# Layer 9: libass (subtitle rendering)
FROM vorbis AS libass
RUN git clone --depth 1 https://github.com/libass/libass.git /tmp/libass \
    && cd /tmp/libass \
    && ./autogen.sh \
    && ./configure --prefix="$FFMPEG_BUILD_ROOT" --disable-shared --enable-static \
    && make -j$(nproc) \
    && make install \
    && echo "✅ libass completed"

# Layer 10: freetype (font rendering for libass)
FROM libass AS freetype
RUN git clone --depth 1 https://gitlab.freedesktop.org/freetype/freetype.git /tmp/freetype \
    && cd /tmp/freetype \
    && ./autogen.sh \
    && ./configure --prefix="$FFMPEG_BUILD_ROOT" --disable-shared --enable-static \
    && make -j$(nproc) \
    && make install \
    && echo "✅ freetype completed"

# Layer 11: fribidi (text layout for libass)
FROM freetype AS fribidi
RUN git clone --depth 1 https://github.com/fribidi/fribidi.git /tmp/fribidi \
    && cd /tmp/fribidi \
    && meson setup build --prefix="$FFMPEG_BUILD_ROOT" --default-library=static \
    && ninja -C build \
    && ninja -C build install \
    && echo "✅ fribidi completed"

# ================================================================
# FFMPEG BUILD STAGE
# ================================================================

FROM fribidi AS ffmpeg-build
COPY scripts/build-ffmpeg.sh /scripts/
RUN chmod +x /scripts/build-ffmpeg.sh

# Download and build FFmpeg
RUN git clone --depth 1 https://git.ffmpeg.org/ffmpeg.git /tmp/ffmpeg \
    && cd /tmp/ffmpeg \
    && /scripts/build-ffmpeg.sh

# ================================================================
# FINAL STAGE - Copy only binaries
# ================================================================

FROM ubuntu:22.04 AS final
RUN apt-get update && apt-get install -y \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ffmpeg-build /opt/ffmpeg/bin/* /usr/local/bin/

# Verify installation
RUN ffmpeg -version && ffprobe -version

WORKDIR /workspace
ENTRYPOINT ["ffmpeg"] 