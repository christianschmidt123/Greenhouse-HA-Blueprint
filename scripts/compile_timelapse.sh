#!/usr/bin/env bash
# compile_timelapse.sh
# Compiles all JPEG snapshots in SNAPSHOT_DIR into an MP4 timelapse.
#
# Usage (standalone):
#   ./compile_timelapse.sh /config/www/timelapse/chamber1/ \
#                          /config/www/timelapse/chamber1_timelapse.mp4 \
#                          24 \
#                          "-vf scale=1920:-2"
#
# Usage via Home Assistant shell_command (see configuration/shell_commands.yaml):
#   The HA service growbox_compile_timelapse calls this script automatically.
#
# Requirements:
#   - ffmpeg installed (available by default in Home Assistant OS)
#   - JPEG files must be sortable by name (use zero-padded timestamps)

set -euo pipefail

SNAPSHOT_DIR="${1:?Usage: $0 <snapshot_dir> <output.mp4> [fps] [scale_filter]}"
OUTPUT="${2:?Missing output path}"
FPS="${3:-24}"
SCALE_FILTER="${4:-}"

if [[ ! -d "$SNAPSHOT_DIR" ]]; then
  echo "ERROR: Snapshot directory '$SNAPSHOT_DIR' does not exist." >&2
  exit 1
fi

FRAME_COUNT=$(find "$SNAPSHOT_DIR" -maxdepth 1 -name '*.jpg' | wc -l)
if [[ "$FRAME_COUNT" -eq 0 ]]; then
  echo "ERROR: No JPEG files found in '$SNAPSHOT_DIR'." >&2
  exit 1
fi

echo "Compiling $FRAME_COUNT frames at ${FPS} fps → $OUTPUT"

# Build optional scale argument
SCALE_ARG=()
if [[ -n "$SCALE_FILTER" ]]; then
  # shellcheck disable=SC2206
  SCALE_ARG=($SCALE_FILTER)
fi

# Use glob input pattern (sorted alphabetically = chronologically)
ffmpeg -y \
  -framerate "$FPS" \
  -pattern_type glob \
  -i "${SNAPSHOT_DIR}*.jpg" \
  "${SCALE_ARG[@]}" \
  -c:v libx264 \
  -preset fast \
  -crf 23 \
  -pix_fmt yuv420p \
  "$OUTPUT"

echo "Done: $OUTPUT"
