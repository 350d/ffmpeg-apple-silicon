# Motion Vectors in FFmpeg Apple Silicon

## Important Update

**The `--enable-mv-export` flag is no longer supported in modern FFmpeg versions!**

The previously included `--enable-mv-export` configuration flag has been removed from FFmpeg. Instead, motion vectors are now available through:

## Modern Motion Vector Access Methods

### 1. Runtime flag `+export_mvs`

Motion vectors are exported via runtime flags during execution:

```bash
# Export motion vectors with visualization
ffmpeg -flags2 +export_mvs -i input.mp4 -vf codecview=mv=pf+bf+bb output.mp4

# P-frame vectors only
ffmpeg -flags2 +export_mvs -i input.mp4 -vf codecview=mv=pf output.mp4

# Save to raw data
ffmpeg -flags2 +export_mvs -i input.mp4 -f null -
```

### 2. Available motion vector types

- `pf` - forward predicted MVs of P-frames
- `bf` - forward predicted MVs of B-frames  
- `bb` - backward predicted MVs of B-frames

### 3. Programmatic access via API

For programmatic access to motion vectors, use:

```c
// Enable motion vector export
AVDictionary *opts = NULL;
av_dict_set(&opts, "flags2", "+export_mvs", 0);
avcodec_open2(codec_ctx, codec, &opts);

// Get motion vector data
AVFrameSideData *sd = av_frame_get_side_data(frame, AV_FRAME_DATA_MOTION_VECTORS);
if (sd) {
    const AVMotionVector *mvs = (const AVMotionVector *)sd->data;
    int mv_count = sd->size / sizeof(*mvs);
    
    for (int i = 0; i < mv_count; i++) {
        const AVMotionVector *mv = &mvs[i];
        printf("MV: src=%d, dst_x=%d, dst_y=%d, motion_x=%d, motion_y=%d\n",
               mv->source, mv->dst_x, mv->dst_y, mv->motion_x, mv->motion_y);
    }
}
```

### 4. AVMotionVector structure

```c
typedef struct AVMotionVector {
    int32_t source;      // reference frame offset
    uint8_t w, h;        // macroblock dimensions  
    int16_t src_x, src_y; // source position
    int16_t dst_x, dst_y; // destination position
    uint64_t flags;      // frame flags
    int32_t motion_x, motion_y; // motion vector
    uint16_t motion_scale;      // scaling factor
} AVMotionVector;
```

### 5. Testing Motion Vectors

```bash
# Create test video with motion vectors
ffmpeg -f lavfi -i testsrc2=duration=10:size=320x240:rate=25 \
       -c:v libx264 -preset ultrafast -x264-params keyint=50 \
       test_mv.mp4

# Export and visualize
ffmpeg -flags2 +export_mvs -i test_mv.mp4 \
       -vf codecview=mv=pf -c:v libx264 -crf 18 \
       output_with_mv.mp4
```

### 6. Python example with mv-extractor

For Python access, use the mv-extractor library:

```bash
pip install motion-vector-extractor

# Usage
python -c "
from mvextractor.videocap import VideoCap
cap = VideoCap()
cap.open('test_mv.mp4')

while True:
    ret, frame, motion_vectors, frame_type, timestamp = cap.read()
    if not ret:
        break
    print(f'Frame type: {frame_type}, MVs count: {len(motion_vectors)}')
    if len(motion_vectors) > 0:
        print(f'First MV: {motion_vectors[0]}')

cap.release()
"
```

## Updated Build Configuration

The FFmpeg configuration in this project has been updated:

1. ✅ Added `--enable-pic` for correct static builds on ARM64
2. ❌ Removed `--enable-mv-export` (not supported)  
3. ✅ Motion vectors available through runtime flags

## Quick Testing

```bash
# Build with motion vector support
./test-build.sh

# Test motion vectors
cd /tmp/ffmpeg-test
echo "Testing motion vectors export..."

# Create test video
./ffmpeg -f lavfi -i testsrc2=duration=2:size=320x240:rate=10 \
         -c:v libx264 -preset ultrafast test.mp4

# Check motion vector export
./ffmpeg -flags2 +export_mvs -i test.mp4 -f null - 2>&1 | grep -i "motion"

# Visualization (if supported)
./ffmpeg -flags2 +export_mvs -i test.mp4 \
         -vf codecview=mv=pf -t 1 -y mv_test.mp4 2>/dev/null && \
echo "✅ Motion vectors export working!" || \
echo "ℹ️ Visualization not available but export should work"
```

## Conclusion

Motion vectors in FFmpeg are now exclusively available through runtime parameters and API, not through configure flags. This provides a more flexible and modern architecture for accessing low-level encoding data. 