#!/usr/bin/env bash
# CI-friendly headless build+snapshot plan and script (Linux)
# This script documents the approach and attempts to run it if dependencies are present.

set -euo pipefail

EXAMPLE_DIR="$(pwd)/../examples/hello-world"
cd "${EXAMPLE_DIR}"
# Ensure artifacts dir is repo-local at nes-ide/artifacts
ARTIFACTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/artifacts"
mkdir -p "$ARTIFACTS_DIR"

echo "Building example..."
make clean
make -j1 || true

ROM_PATH="${EXAMPLE_DIR}/hello.nes"
if [[ ! -f "$ROM_PATH" ]]; then
  echo "Build didn't produce $ROM_PATH; aborting." >&2
  exit 1
fi

# CI headless approach notes:
# 1) Start Xvfb on display :99
# 2) Export DISPLAY=:99 and run mednafen in background
# 3) Use xdotool to focus mednafen window and send keys (requires X window manager)
#    - Alternatively, use mednafen -qtrecord <file> to create a QuickTime movie then use ffmpeg to extract a frame
# 4) Copy resulting PNG / extracted frame to artifacts

if command -v Xvfb >/dev/null 2>&1 && command -v ffmpeg >/dev/null 2>&1; then
  echo "Xvfb and ffmpeg available — attempting headless run (best-effort)."
  # Start Xvfb in background
  Xvfb :99 -screen 0 640x480x24 &
  XVFB_PID=$!
  export DISPLAY=:99
  sleep 0.5

  MEDNAFEN=$(command -v mednafen || true)
  if [[ -z "$MEDNAFEN" ]]; then
    echo "mednafen not installed in CI environment; please install mednafen." >&2
    kill $XVFB_PID || true
    exit 1
  fi

  # Start mednafen with -qtrecord to write a movie file
  MEDNAFEN_HOME=$(mktemp -d -t mednafen_home_ci_XXXX)
  export MEDNAFEN_HOME
  mkdir -p "$MEDNAFEN_HOME"
  MOVIE_OUT="$MEDNAFEN_HOME/rec.mov"

  "$MEDNAFEN" -qtrecord "$MOVIE_OUT" "$ROM_PATH" &> "$MEDNAFEN_HOME/mednafen.log" &
  MF_PID=$!
  sleep 2

  # Let mednafen run a few frames, then kill it
  sleep 1
  kill $MF_PID || true
  wait $MF_PID 2>/dev/null || true

  # If movie exists, extract frame 00:00:00 using ffmpeg
  if [[ -f "$MOVIE_OUT" ]]; then
    OUT="$ARTIFACTS_DIR/$(basename ${ROM_PATH} .nes)_mednafen_ci_snapshot.png"
    ffmpeg -y -i "$MOVIE_OUT" -ss 0 -frames:v 1 "$OUT"
    echo "Saved CI snapshot to $OUT"
  else
    echo "No movie found at $MOVIE_OUT; check $MEDNAFEN_HOME/mednafen.log" >&2
  fi

  kill $XVFB_PID || true
else
  echo "Xvfb or ffmpeg not available — this script documents the CI approach; install those deps to run headless." >&2
  exit 2
fi
