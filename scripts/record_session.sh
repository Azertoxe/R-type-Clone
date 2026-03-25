#!/usr/bin/env bash
set -euo pipefail

OUT_FILE="${1:-r-type-session-$(date +%Y%m%d-%H%M%S).mp4}"
FPS="${FPS:-30}"
SIZE="${SIZE:-1280x720}"
DISPLAY_ID="${DISPLAY:-:0.0}"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "[record_session] ffmpeg is required. Install it first."
  exit 1
fi

echo "[record_session] Recording display ${DISPLAY_ID} at ${SIZE} ${FPS}fps"
echo "[record_session] Output: ${OUT_FILE}"
echo "[record_session] Stop with Ctrl+C"

ffmpeg -y \
  -video_size "${SIZE}" \
  -framerate "${FPS}" \
  -f x11grab \
  -i "${DISPLAY_ID}" \
  -c:v libx264 \
  -preset veryfast \
  -pix_fmt yuv420p \
  "${OUT_FILE}"
