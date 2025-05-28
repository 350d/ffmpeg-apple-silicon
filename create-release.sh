#!/bin/bash

# Create a new release automatically
set -e

# Default version if not provided
VERSION=${1:-"v$(date +%Y.%m.%d)"}

echo "🚀 Creating release $VERSION..."

# Validate we're on main branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    echo "❌ Error: Must be on main/master branch. Currently on: $CURRENT_BRANCH"
    exit 1
fi

# Check if tag already exists
if git tag -l "$VERSION" | grep -q "$VERSION"; then
    echo "❌ Error: Tag $VERSION already exists"
    exit 1
fi

# Ensure we have latest changes
echo "📥 Pulling latest changes..."
git pull origin $(git rev-parse --abbrev-ref HEAD)

# Run quick test first
echo "🧪 Running quick test before release..."
./test-build.sh

# Create and push tag
echo "🏷️ Creating tag $VERSION..."
git tag -a "$VERSION" -m "Release $VERSION

## Features
- Static FFmpeg build optimized for Apple Silicon
- Full codec support: H.264, H.265, AV1, VP9, x264, x265
- Hardware acceleration via VideoToolbox
- Modern Motion Vector API support
- ARM64 optimized with --enable-pic

## Build Date
$(date '+%Y-%m-%d %H:%M:%S UTC')

## Technical Details
- Platform: Apple Silicon (ARM64)
- Build type: Static
- Motion vectors: Modern runtime API (flags2 +export_mvs)
- PIC enabled: Yes
"

echo "📤 Pushing tag to GitHub..."
git push origin "$VERSION"

echo "✅ Release $VERSION created successfully!"
echo ""
echo "🎯 Next steps:"
echo "1. Go to GitHub Actions to monitor the build"
echo "2. Check https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"
echo "3. Release artifacts will be available in ~3 hours"
echo "4. Docker image will be published to GitHub Container Registry"
echo ""
echo "📦 Release will include:"
echo "- ffmpeg-apple-silicon-$VERSION.tar.gz (static binaries)"
echo "- checksums.txt (SHA256 verification)"
echo "- Docker image: ghcr.io/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^.]*\).*/\1/' | tr '[:upper:]' '[:lower:]')/ffmpeg:$VERSION" 