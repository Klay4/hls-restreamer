#!/bin/sh
set -e

FIFO="/shared/input.ts"
HLS_DIR="/shared/hls"
MEDIA_PLAYLIST="$HLS_DIR/stream_media.m3u8"
MASTER_PLAYLIST="$HLS_DIR/stream.m3u8"

# ── Wait for streamlink to create the FIFO ──
echo "[ffmpeg] Waiting for FIFO at $FIFO …"
while [ ! -p "$FIFO" ]; do
  sleep 1
done
echo "[ffmpeg] FIFO ready."

mkdir -p "$HLS_DIR"

# ── Background job: write/refresh the multivariant (master) playlist ──
write_master() {
  while true; do
    if [ -f "$MEDIA_PLAYLIST" ]; then
      cat > "$MASTER_PLAYLIST" << 'M3U8'
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=2000000,RESOLUTION=1920x1080,CODECS="avc1.640028,mp4a.40.2"
stream_media.m3u8
M3U8
      echo "[ffmpeg] Master playlist written."
      sleep 5
    else
      sleep 1
    fi
  done
}
write_master &
MASTER_PID=$!

echo "[ffmpeg] Starting HLS segmenter → $MEDIA_PLAYLIST"
echo "[ffmpeg] NOTE: Transcoding video to H.264 (RAI likely sends H.265 which Xibo cannot decode)"

while true; do
  ffmpeg \
    -err_detect ignore_err \
    -i "$FIFO" \
    -c:v libx264 \
    -preset ultrafast \
    -tune film \
    -x264-params "scenecut=0:sync-lookahead=0:rc-lookahead=0:bframe=0" \
    -crf 23 \
    -pix_fmt yuv420p \
    -c:a aac \
    -ac 2 \
    -ar 44100 \
    -f hls \
    -hls_time 4 \
    -hls_list_size 10 \
    -hls_flags delete_segments+temp_file \
    -hls_segment_type mpegts \
    -hls_segment_filename "$HLS_DIR/seg_%05d.ts" \
    "$MEDIA_PLAYLIST" \
    2>&1 || true

  echo "[ffmpeg] FFmpeg exited. Restarting in 2 s "
  sleep 2
done

kill $MASTER_PID 2>/dev/null