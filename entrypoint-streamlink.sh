#!/bin/sh
set -e
FIFO="/shared/input.ts"
STREAM_URL="${STREAM_URL:-https://mediapolis.rai.it/relinker/relinkerServlet.htm?cont=358025&output=16}"
STREAM_QUALITY="${STREAM_QUALITY:-best}"

# Create the FIFO (named pipe) once; harmless if it already exists
[ -p "$FIFO" ] || mkfifo "$FIFO"

echo "[streamlink] Starting stream: $STREAM_URL  quality=$STREAM_QUALITY"

# Retry loop — if streamlink exits (stream ended / network blip) restart after 5 s
while true; do
  # stderr goes to container log (NOT into the FIFO).
  # pv adds a 32 MB ring-buffer between streamlink and the FIFO so that
  # small write/read timing mismatches don't stall the pipe.
  streamlink \
    --stdout \
    --stream-types hls,http \
    --http-no-ssl-verify \
    "$STREAM_URL" \
    "$STREAM_QUALITY" \
    2>/dev/null \
  | pv -q -C -B 32M > "$FIFO" \
    || true

  echo "[streamlink] Stream ended or errored. Retrying in 5 s …"
  sleep 5
done