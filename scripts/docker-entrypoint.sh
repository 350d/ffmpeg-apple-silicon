#!/bin/bash

# Docker entrypoint for FFmpeg container

set -e

# Copy binaries to output directory if COPY_BINARIES is set
if [[ "$COPY_BINARIES" == "true" && -n "$OUTPUT_DIR" ]]; then
    echo "📦 Copying binaries to $OUTPUT_DIR..."
    mkdir -p "$OUTPUT_DIR"
    cp -v "$BIN_DIR"/* "$OUTPUT_DIR/"
    echo "✅ Binaries copied successfully"
fi

# If running ffmpeg command, use our built version
if [[ "$1" == "ffmpeg" || "$1" == "ffprobe" || "$1" == "ffplay" ]]; then
    exec "$BIN_DIR/$@"
fi

# Otherwise, run the command as-is
exec "$@" 