# Motion Vectors Support in FFmpeg Apple Silicon

This FFmpeg build includes comprehensive motion vectors support for advanced video analysis, computer vision, and research applications.

## Overview

Motion vectors represent the movement of blocks of pixels between frames in video compression. They are essential for:
- Video compression efficiency analysis
- Motion detection and tracking
- Computer vision applications
- Sports and surveillance analysis
- Academic research

## Basic Usage

### Export Motion Vectors as Video Overlay

```bash
# Show all motion vectors (P-frames + B-frames + backward)
./ffmpeg -flags2 +export_mvs -i input.mp4 -vf codecview=mv=pf+bf+bb output_with_vectors.mp4

# Show only P-frame motion vectors (most common)
./ffmpeg -flags2 +export_mvs -i input.mp4 -vf codecview=mv=pf output_pframe_vectors.mp4

# Show B-frame forward motion vectors
./ffmpeg -flags2 +export_mvs -i input.mp4 -vf codecview=mv=bf output_bframe_forward.mp4
```

### Export Motion Vectors Data

```bash
# Export motion vectors data to text file
./ffmpeg -flags2 +export_mvs -i input.mp4 -vf codecview=mv=pf -f null - 2> motion_data.txt

# Export with frame information
./ffmpeg -flags2 +export_mvs -i input.mp4 -vf "codecview=mv=pf,showinfo" -f null - 2> detailed_analysis.log
```

## Advanced Examples

### Motion Detection Pipeline

```bash
# Create motion heatmap
./ffmpeg -flags2 +export_mvs -i input.mp4 \
  -vf "codecview=mv=pf,scale=640:480" \
  -c:v libx264 -crf 18 motion_heatmap.mp4

# Extract high-motion frames
./ffmpeg -flags2 +export_mvs -i input.mp4 \
  -vf "codecview=mv=pf,select='gt(scene,0.3)'" \
  -vsync vfr high_motion_frames_%03d.png
```

### Sports Analysis

```bash
# Track ball movement in sports video
./ffmpeg -flags2 +export_mvs -i sports_game.mp4 \
  -vf "codecview=mv=pf+bf,scale=1280:720" \
  -c:v h264_videotoolbox -b:v 5M \
  sports_analysis.mp4

# Extract motion statistics
./ffmpeg -flags2 +export_mvs -i sports_game.mp4 \
  -vf "codecview=mv=pf,showinfo" \
  -f null - 2> sports_motion_stats.txt
```

### Surveillance Applications

```bash
# Motion detection for security cameras
./ffmpeg -flags2 +export_mvs -i security_feed.mp4 \
  -vf "codecview=mv=pf,select='gt(scene,0.1)'" \
  -vsync vfr motion_detected_%04d.jpg

# Create motion timeline
./ffmpeg -flags2 +export_mvs -i security_feed.mp4 \
  -vf "codecview=mv=pf,scale=320:240" \
  -c:v libx264 -crf 25 motion_timeline.mp4
```

## Motion Vector Flags Explained

| Flag | Description |
|------|-------------|
| `pf` | P-frame forward motion vectors |
| `bf` | B-frame forward motion vectors |  
| `bb` | B-frame backward motion vectors |
| `pf+bf` | All forward motion vectors |
| `pf+bf+bb` | All motion vectors |

## Frame Types

- **I-frames**: Intra-coded (no motion vectors)
- **P-frames**: Predicted from previous frame (forward motion vectors)
- **B-frames**: Bi-predicted from past and future frames (forward + backward motion vectors)

## Performance Optimization

### Hardware Acceleration with Motion Vectors

```bash
# Use VideoToolbox encoding while preserving motion vectors
./ffmpeg -flags2 +export_mvs -i input.mp4 \
  -vf codecview=mv=pf \
  -c:v h264_videotoolbox -b:v 8M \
  output_accelerated.mp4

# HEVC with motion vectors
./ffmpeg -flags2 +export_mvs -i input.mp4 \
  -vf codecview=mv=pf+bf \
  -c:v hevc_videotoolbox -b:v 10M \
  output_hevc_vectors.mp4
```

### Batch Processing

```bash
# Process multiple files
for file in *.mp4; do
  ./ffmpeg -flags2 +export_mvs -i "$file" \
    -vf codecview=mv=pf \
    -c:v libx264 -crf 20 \
    "vectors_${file}"
done
```

## Research Applications

### Computer Vision Research

```bash
# Extract motion vectors for optical flow comparison
./ffmpeg -flags2 +export_mvs -i dataset_video.mp4 \
  -vf "codecview=mv=pf,format=yuv420p" \
  -c:v rawvideo motion_vectors_raw.yuv

# Generate training data for ML models
./ffmpeg -flags2 +export_mvs -i training_video.mp4 \
  -vf "codecview=mv=pf,showinfo" \
  -f null - 2> ml_training_data.csv
```

### Video Compression Analysis

```bash
# Analyze compression efficiency
./ffmpeg -flags2 +export_mvs -i original.mp4 \
  -vf "codecview=mv=pf+bf+bb,showinfo" \
  -c:v libx264 -x264-params log-level=full \
  compressed_analysis.mp4 2> compression_log.txt
```

## Troubleshooting

### Common Issues

1. **No motion vectors visible**: Ensure input video has P or B frames
2. **Performance issues**: Use hardware acceleration with VideoToolbox
3. **Large output files**: Adjust CRF value or use hardware encoding

### Verification

```bash
# Check if motion vectors are supported
./ffmpeg -hide_banner -filters | grep codecview

# Verify export flag is working
./ffmpeg -flags2 +export_mvs -f lavfi -i testsrc=duration=1:rate=30 \
  -vf codecview=mv=pf test_vectors.mp4
```

## Integration with Other Tools

### OpenCV Integration

The motion vectors data can be parsed and used with OpenCV for advanced computer vision applications.

### Academic Research

Motion vectors extracted with this build are suitable for:
- Video compression research
- Motion estimation algorithm comparison
- Object tracking algorithm development
- Video quality assessment studies

## References

- [FFmpeg Motion Vectors Documentation](https://ffmpeg.org/ffmpeg-filters.html#codecview)
- [Video Compression Standards](https://www.itu.int/rec/T-REC-H.264)
- [Motion Vector Research Papers](https://scholar.google.com/scholar?q=motion+vectors+video+compression) 