#!/usr/bin/env zsh
# Build hello-world and run mednafen snapshot automation (macOS)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXAMPLE_DIR="$SCRIPT_DIR/../examples/hello-world"
ARTIFACTS_DIR="$SCRIPT_DIR/../artifacts"
mkdir -p "$ARTIFACTS_DIR"
cd "${EXAMPLE_DIR}"

echo "Building example in ${EXAMPLE_DIR}..."
make clean
make -j1

ROM_PATH="${EXAMPLE_DIR}/hello.nes"
if [[ ! -f "$ROM_PATH" ]]; then
  echo "Build failed: $ROM_PATH not found" >&2
  exit 1
fi

# Run the mednafen automation script (assumes tools/mednafen_auto_movie_snapshot.sh is executable)
TOOLS_DIR="$(pwd)/../../tools"
"${TOOLS_DIR}/mednafen_auto_movie_snapshot.sh" "$ROM_PATH"

# Copy snapshot into example directory if present
EXPECTED="$ARTIFACTS_DIR/$(basename ${ROM_PATH} .nes)_mednafen_snapshot.png"
if [[ -f "$EXPECTED" ]]; then
  cp "$EXPECTED" "${EXAMPLE_DIR}/mednafen_snapshot.png" || true
  echo "Saved snapshot to ${EXAMPLE_DIR}/mednafen_snapshot.png"
else
  echo "No artifact found at $EXPECTED; check MEDNAFEN_HOME and logs." >&2
fi

