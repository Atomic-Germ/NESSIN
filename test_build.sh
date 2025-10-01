#!/usr/bin/env zsh
# Robust test runner for building and validating the example ROM
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
EXAMPLE_DIR="$REPO_ROOT/nes-ide/examples/hello-world"
TMPDIR="$REPO_ROOT/tmp/test_build_$$"
mkdir -p "$TMPDIR"

echo "Building example in $EXAMPLE_DIR"
cd "$EXAMPLE_DIR"
make clean
make -j1

# Keep temporary artifacts in repo-local tmp for inspection
if [[ -f hello.tmp.nes ]]; then
	cp hello.tmp.nes "$TMPDIR/hello.tmp.nes"
fi
cp hello.nes "$TMPDIR/test.nes"
cp hello.chr "$TMPDIR/test.chr" || true

# Also place a copy at the repository root named test.nes so CI steps that expect
# a top-level `test.nes` (and `mv test.nes artifacts/test.nes`) succeed.
cp "$TMPDIR/test.nes" "$REPO_ROOT/test.nes" || true

echo "Running mednafen against $TMPDIR/test.nes (mednafen.log -> $TMPDIR/mednafen.log)"
MEDNAFEN_LOG="$TMPDIR/mednafen.log"
if command -v mednafen >/dev/null 2>&1; then
	# Launch mednafen in the background and monitor log for successful load lines.
	mednafen "$TMPDIR/test.nes" > "$MEDNAFEN_LOG" 2>&1 &
	MEDNAFEN_PID=$!
	LOAD_TIMEOUT=10  # seconds
	START_TIME=$(date +%s)
	SUCCESS=0
	# Poll the log until we see PRG ROM line or timeout
	while (( $(date +%s) - START_TIME < LOAD_TIMEOUT )); do
		if grep -qE 'PRG ROM:' "$MEDNAFEN_LOG"; then
			SUCCESS=1
			break
		fi
		if ! kill -0 $MEDNAFEN_PID 2>/dev/null; then
			break
		fi
		sleep 0.2
	done
	if (( SUCCESS == 1 )); then
		echo "Detected successful mednafen load (PRG ROM line)."
		if [[ -z "${KEEP_MEDNAFEN:-}" ]]; then
			kill $MEDNAFEN_PID 2>/dev/null || true
			wait $MEDNAFEN_PID 2>/dev/null || true
		else
			echo "KEEP_MEDNAFEN set; leaving mednafen running (pid $MEDNAFEN_PID)."
		fi
	else
		echo "Did not detect successful mednafen load within ${LOAD_TIMEOUT}s (pid $MEDNAFEN_PID)." >&2
		# Attempt graceful termination
		kill $MEDNAFEN_PID 2>/dev/null || true
		wait $MEDNAFEN_PID 2>/dev/null || true
	fi
else
	echo "mednafen not found on PATH; skipping emulation run" > "$MEDNAFEN_LOG"
fi

if grep -q "Unrecognized file format" "$MEDNAFEN_LOG" 2>/dev/null; then
	echo "ERROR: mednafen reported 'Unrecognized file format'" >&2
	echo "Check $MEDNAFEN_LOG and $TMPDIR for details." >&2
	exit 1
fi

echo "test.nes header (64 bytes):"
xxd -g1 -l64 "$TMPDIR/test.nes" || true
echo
echo "PRG count byte (offset 4):"
xxd -p -s 4 -l1 "$TMPDIR/test.nes" || true
echo
echo "test.chr header (first 32 bytes):"
xxd -g1 -l32 "$TMPDIR/test.chr" || true

echo "Mednafen log (last 40 lines):"
tail -n 40 "$MEDNAFEN_LOG" || true

echo "Done. Temporary artifacts in: $TMPDIR"

exit 0