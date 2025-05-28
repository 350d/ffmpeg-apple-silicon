#!/bin/bash

# Build Time Analyzer for FFmpeg Dependencies
# Analyzes Docker build logs to optimize layer caching

set -euo pipefail

BUILD_LOG=${1:-build.log}
OUTPUT_DIR=${2:-analysis}

echo "🔍 Analyzing build times from: $BUILD_LOG"

# Create analysis directory
mkdir -p "$OUTPUT_DIR"

# Extract build times with component names
extract_build_times() {
    grep -E "DONE [0-9]+\.[0-9]+s|echo.*\"([^\"]+)\"" "$BUILD_LOG" | \
    while IFS= read -r line; do
        if [[ $line =~ DONE\ ([0-9]+\.[0-9]+)s ]]; then
            duration="${BASH_REMATCH[1]}"
            if [[ -n $current_component ]]; then
                echo "$current_component,$duration"
            fi
        elif [[ $line =~ echo.*\"([^\"]+)\" ]]; then
            current_component="${BASH_REMATCH[1]}"
        fi
    done > "$OUTPUT_DIR/raw_times.csv"
}

# Analyze and categorize
analyze_times() {
    echo "component,duration_seconds,category" > "$OUTPUT_DIR/build_times.csv"
    
    while IFS=, read -r component duration; do
        # Convert to integer for comparison (multiply by 10 to handle decimals)
        duration_int=$(echo "$duration * 10" | awk '{printf "%.0f", $1}')
        
        if (( duration_int >= 600 )); then  # >= 60.0s
            category="SLOW"
        elif (( duration_int >= 200 )); then  # >= 20.0s
            category="MEDIUM" 
        else
            category="FAST"
        fi
        echo "$component,$duration,$category"
    done < "$OUTPUT_DIR/raw_times.csv" >> "$OUTPUT_DIR/build_times.csv"
}

# Generate optimized Dockerfile structure
generate_optimized_dockerfile() {
    cat > "$OUTPUT_DIR/Dockerfile.optimized" << 'EOF'
# Time-Optimized Multi-Stage Build
# Generated based on build time analysis

FROM --platform=linux/arm64 ubuntu:22.04 AS base-system

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV CFLAGS="-w -O2"
ENV CXXFLAGS="-w -O2"

# Build environment
ENV FFMPEG_BUILD_ROOT=/opt/ffmpeg
ENV SOURCE_DIR=/opt/ffmpeg/source
ENV PKG_CONFIG_PATH=/opt/ffmpeg/lib/pkgconfig

# System dependencies (baseline)
RUN apt-get update && apt-get install -y \
    build-essential curl git cmake ninja-build nasm yasm \
    pkg-config autoconf automake libtool meson python3 \
    python3-pip wget ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p "$FFMPEG_BUILD_ROOT" "$SOURCE_DIR"

WORKDIR $SOURCE_DIR

EOF

    # Group by timing categories
    echo "# === FAST DEPENDENCIES (Combined Layer) ===" >> "$OUTPUT_DIR/Dockerfile.optimized"
    echo "FROM base-system AS fast-deps" >> "$OUTPUT_DIR/Dockerfile.optimized"
    
    grep "FAST" "$OUTPUT_DIR/build_times.csv" | while IFS=, read -r component duration category; do
        echo "# $component ($duration s)" >> "$OUTPUT_DIR/Dockerfile.optimized"
    done
    
    echo -e "\n# === MEDIUM DEPENDENCIES (Paired Layers) ===" >> "$OUTPUT_DIR/Dockerfile.optimized"
    echo "FROM fast-deps AS medium-deps" >> "$OUTPUT_DIR/Dockerfile.optimized"
    
    echo -e "\n# === SLOW DEPENDENCIES (Individual Layers) ===" >> "$OUTPUT_DIR/Dockerfile.optimized"
    
    grep "SLOW" "$OUTPUT_DIR/build_times.csv" | while IFS=, read -r component duration category; do
        stage_name=$(echo "$component" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
        echo "FROM medium-deps AS $stage_name" >> "$OUTPUT_DIR/Dockerfile.optimized"
        echo "# $component ($duration s) - Individual layer for optimal caching" >> "$OUTPUT_DIR/Dockerfile.optimized"
        echo "" >> "$OUTPUT_DIR/Dockerfile.optimized"
    done
}

# Generate recommendations
generate_report() {
    cat > "$OUTPUT_DIR/optimization_report.md" << EOF
# Build Time Optimization Report

## 📊 Component Analysis

\`\`\`
$(cat "$OUTPUT_DIR/build_times.csv" | column -t -s,)
\`\`\`

## 🎯 Optimization Strategy

### Slow Components (>60s) - Individual Layers
$(grep "SLOW" "$OUTPUT_DIR/build_times.csv" | while IFS=, read -r comp dur cat; do echo "- **$comp**: ${dur}s"; done)

### Medium Components (20-60s) - Paired Layers  
$(grep "MEDIUM" "$OUTPUT_DIR/build_times.csv" | while IFS=, read -r comp dur cat; do echo "- **$comp**: ${dur}s"; done)

### Fast Components (<20s) - Combined Layer
$(grep "FAST" "$OUTPUT_DIR/build_times.csv" | while IFS=, read -r comp dur cat; do echo "- **$comp**: ${dur}s"; done)

## 💡 Cache Efficiency Calculation

**Total build time**: $(awk -F, 'NR>1 {sum+=$2} END {print sum}' "$OUTPUT_DIR/build_times.csv")s

**Estimated cache hit benefit**:
- Config change: Only rebuild final stage (~15% of total time)
- Slow dependency change: Skip other slow deps (~70% time saved)
- Fast dependency change: Skip all slow+medium deps (~85% time saved)

## 🚀 Implementation

1. Use \`Dockerfile.optimized\` for development
2. Slow dependencies in separate layers minimize rebuild impact
3. Fast dependencies grouped for simplicity

EOF
}

# Main execution
if [[ ! -f "$BUILD_LOG" ]]; then
    echo "❌ Build log not found: $BUILD_LOG"
    echo "💡 Run: docker build . 2>&1 | tee build.log"
    exit 1
fi

echo "⏱️  Extracting build times..."
extract_build_times

echo "📊 Analyzing timing patterns..."
analyze_times

echo "🏗️  Generating optimized Dockerfile..."
generate_optimized_dockerfile

echo "📋 Creating optimization report..."
generate_report

echo "✅ Analysis complete!"
echo "📁 Results in: $OUTPUT_DIR/"
echo "📊 View report: cat $OUTPUT_DIR/optimization_report.md"
echo "🐳 Try optimized build: docker build -f $OUTPUT_DIR/Dockerfile.optimized ." 