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

# Temporary mednafen base dir so snaps/movies go somewhere predictable
MEDNAFEN_HOME=$(mktemp -d -t mednafen_home_XXXX)
export MEDNAFEN_HOME
mkdir -p "$MEDNAFEN_HOME/snaps" "$MEDNAFEN_HOME/mcm"

LOGFILE="$MEDNAFEN_HOME/mednafen.log"
PIDFILE="$MEDNAFEN_HOME/mednafen.pid"

echo "MEDNAFEN_HOME=$MEDNAFEN_HOME"
echo "Starting mednafen: $MEDNAFEN $ROM_PATH"

# Launch mednafen in background and save pid
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

echo "Listing snaps and movies under MEDNAFEN_HOME=$MEDNAFEN_HOME"
ls -la "$MEDNAFEN_HOME/snaps" || true
ls -la "$MEDNAFEN_HOME/mcm" || true

# If a QuickTime movie was created via -qtrecord it will be elsewhere; check mednafen log for qtrecord mentions
## Locate the newest PNG snapshot (look in snaps/ first then MEDNAFEN_HOME root)
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

if [[ -n "$SNAP_FILE" ]]; then
  echo "Found snapshot: $SNAP_FILE"
  echo "Copying snapshot to repo root as mednafen_snapshot.png"
  cp "$SNAP_FILE" "$(pwd)/mednafen_snapshot.png" || true
  echo "Saved: $(pwd)/mednafen_snapshot.png"
else
  echo "No snapshot PNG found in $MEDNAFEN_HOME or $MEDNAFEN_HOME/snaps"
fi

echo "Done. MEDNAFEN_HOME retained at: $MEDNAFEN_HOME (not removed)"
echo "If you want to reuse a clean MEDNAFEN_HOME, remove the directory above before re-running."

exit 0
