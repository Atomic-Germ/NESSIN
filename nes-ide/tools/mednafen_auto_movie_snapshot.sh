#!/usr/bin/env zsh
# Automated Mednafen run: start movie recording, take a snapshot, stop recording, extract a frame
# Usage: ./mednafen_auto_movie_snapshot.sh /absolute/path/to/hello.nes

set -euo pipefail
# Allow globs that don't match to expand to empty (avoid zsh 'no matches found')
setopt NULL_GLOB

ROM_PATH=${1:-}
if [[ -z "$ROM_PATH" ]]; then
  echo "Usage: $0 /absolute/path/to/your.rom.nes"
  exit 2
fi

if [[ ! -f "$ROM_PATH" ]]; then
  echo "ROM not found: $ROM_PATH"
  exit 3
fi

MEDNAFEN=$(command -v mednafen || true)
if [[ -z "$MEDNAFEN" ]]; then
  echo "mednafen binary not found on PATH. Install Mednafen (homebrew: brew install mednafen) or add it to PATH." >&2
  exit 4
fi

# Use a repo-local ./tmp path (repository root) so artifacts and logs stay inside the workspace
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MEDNAFEN_HOME="$REPO_ROOT/tmp/nes-ide_mednafen_home_$$"
export MEDNAFEN_HOME
# Start fresh for each run
rm -rf "$MEDNAFEN_HOME" 2>/dev/null || true
mkdir -p "$MEDNAFEN_HOME/snaps" "$MEDNAFEN_HOME/mcm"

LOGFILE="$MEDNAFEN_HOME/mednafen.log"
PIDFILE="$MEDNAFEN_HOME/mednafen.pid"

# Artifacts directory (repo-local)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARTIFACTS_DIR="$SCRIPT_DIR/../artifacts"
mkdir -p "$ARTIFACTS_DIR"

echo "MEDNAFEN_HOME=$MEDNAFEN_HOME"
echo "MEDNAFEN binary: $MEDNAFEN"

# If ffmpeg is available, use mednafen -qtrecord to create a movie and extract a frame (more reliable)
RECORD_MODE=0
if command -v ffmpeg >/dev/null 2>&1; then
  RECORD_MODE=1
  MOVIE_OUT="$MEDNAFEN_HOME/mednafen_record.mov"
  echo "ffmpeg available -> using -qtrecord fallback. Movie will be: $MOVIE_OUT"
  "$MEDNAFEN" -qtrecord "$MOVIE_OUT" "$ROM_PATH" &> "$LOGFILE" &
  MF_PID=$!
  echo $MF_PID > "$PIDFILE"
  echo "mednafen pid: $MF_PID (log: $LOGFILE)"
  # Let mednafen run a brief amount of time to capture frames
  sleep 0.8
  echo "Stopping mednafen (record mode)..."
  kill $MF_PID 2>/dev/null || true
  wait $MF_PID 2>/dev/null || true
else
  echo "Starting mednafen: $MEDNAFEN $ROM_PATH"
  "$MEDNAFEN" "$ROM_PATH" &> "$LOGFILE" &
  MF_PID=$!
  echo $MF_PID > "$PIDFILE"
  echo "mednafen pid: $MF_PID (log: $LOGFILE)"

  sleep 1

  # helper: bring mednafen process to front using System Events (AppleScript)
  bring_front() {
    local pid=$1
    # Try up to 10 times to make the process frontmost
    local i
    for i in {1..10}; do
      if osascript -e "tell application \"System Events\" to set frontmost of first process whose unix id is $pid to true" >/dev/null 2>&1; then
        return 0
      fi
      sleep 0.35
    done
    return 1
  }

  if ! bring_front $MF_PID; then
    echo "Warning: unable to bring mednafen window to front. Keystroke delivery may fail." >&2
  fi

  echo "Starting movie recording (SHIFT+F5)"
  # SHIFT+F5 key code on macOS is 96 with shift modifier
  osascript -e "tell application \"System Events\" to key code 96 using {shift down}"
  sleep 0.3

  echo "Give mednafen a moment to start recording..."
  sleep 0.6

  echo "Take snapshot (F9)"
  osascript -e "tell application \"System Events\" to key code 101"

  sleep 0.4

  echo "Stop movie recording (SHIFT+F5)"
  osascript -e "tell application \"System Events\" to key code 96 using {shift down}"

  sleep 0.3

  echo "Exit Mednafen (F12)"
  osascript -e "tell application \"System Events\" to key code 111"

  echo "Waiting for mednafen to exit..."
  wait $MF_PID 2>/dev/null || true
fi

echo "Listing snaps and movies under MEDNAFEN_HOME=$MEDNAFEN_HOME"
ls -la "$MEDNAFEN_HOME/snaps" || true
ls -la "$MEDNAFEN_HOME/mcm" || true

# Locate the newest PNG snapshot (look in snaps/ first then MEDNAFEN_HOME root)
SNAP_FILE=""
snaps=( "$MEDNAFEN_HOME"/snaps/*.png )
if [[ ${#snaps[@]} -gt 0 ]]; then
  SNAP_FILE=$(ls -1t "${snaps[@]}" 2>/dev/null | head -n1 || true)
fi
if [[ -z "$SNAP_FILE" ]]; then
  rootsnaps=( "$MEDNAFEN_HOME"/*.png )
  if [[ ${#rootsnaps[@]} -gt 0 ]]; then
    SNAP_FILE=$(ls -1t "${rootsnaps[@]}" 2>/dev/null | head -n1 || true)
  fi
fi

BASENAME=$(basename "$ROM_PATH" .nes)
if [[ -n "$SNAP_FILE" ]]; then
  echo "Found snapshot: $SNAP_FILE"
  OUT="$ARTIFACTS_DIR/${BASENAME}_mednafen_snapshot.png"
  mkdir -p "$(dirname "$OUT")"
  cp "$SNAP_FILE" "$OUT" || true
  echo "Copied snapshot to $OUT"
  echo "Done. MEDNAFEN_HOME retained at: $MEDNAFEN_HOME (not removed)"
  echo "If you want to reuse a clean MEDNAFEN_HOME, remove the directory above before re-running."
  exit 0
fi

# If we used record mode and have a movie, try extracting a frame with ffmpeg
if [[ "$RECORD_MODE" -eq 1 ]]; then
  MOVIE_IN="$MEDNAFEN_HOME/mednafen_record.mov"
  if [[ -f "$MOVIE_IN" ]] && command -v ffmpeg >/dev/null 2>&1; then
    OUT="$ARTIFACTS_DIR/${BASENAME}_mednafen_snapshot.png"
    echo "Extracting frame from movie $MOVIE_IN -> $OUT"
    mkdir -p "$(dirname "$OUT")"
    ffmpeg -y -i "$MOVIE_IN" -frames:v 1 -q:v 2 "$OUT" &> /dev/null || true
    if [[ -f "$OUT" ]]; then
      echo "Extracted snapshot to $OUT"
      echo "Done. MEDNAFEN_HOME retained at: $MEDNAFEN_HOME (not removed)"
      exit 0
    else
      echo "ffmpeg failed to extract a frame or output missing: $OUT" >&2
    fi
  else
    echo "No movie file found at $MOVIE_IN or ffmpeg missing; cannot extract frame." >&2
  fi
fi

echo "No snapshot PNG found in $MEDNAFEN_HOME or $MEDNAFEN_HOME/snaps and no movie frame extracted. See $LOGFILE for mednafen log."
echo "Done. MEDNAFEN_HOME retained at: $MEDNAFEN_HOME (not removed)"
echo "If you want to reuse a clean MEDNAFEN_HOME, remove the directory above before re-running."
exit 2
