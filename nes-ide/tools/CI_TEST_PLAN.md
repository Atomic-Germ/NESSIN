# CI-friendly Test Plan for NES-IDE hello-world

This document describes a repeatable CI workflow to build the `hello-world` ROM, run it headlessly in Mednafen, and extract a single frame as a PNG artifact.

Goals
- Build the `hello.nes` using cc65 (cl65).
- Run Mednafen headlessly (Xvfb) and either record a short movie with `-qtrecord` or simulate keypresses with `xdotool` to take a snapshot.
- Extract a single frame from the recorded movie with `ffmpeg` (or pick the produced snapshot PNG).
- Upload the extracted PNG as a CI artifact for inspection.

Required packages (Linux runner)
- cc65 (cl65) — build toolchain
- mednafen — emulator (must support `-qtrecord` on the target platform)
- xvfb (X virtual framebuffer)
- xdotool (optional; for simulating keypresses if you prefer snapshot keys)
- ffmpeg — extract frames from recorded movie

High-level approach (recommended)
1. Build
   - make -C nes-ide/examples/hello-world
2. Start Xvfb
   - Xvfb :99 -screen 0 640x480x24 &
   - export DISPLAY=:99
3. Run Mednafen and record movie
   - MEDNAFEN_HOME=$(mktemp -d)
   - mednafen -qtrecord "$MEDNAFEN_HOME/rec.mov" path/to/hello.nes &> "$MEDNAFEN_HOME/mednafen.log" &
   - let it run for a short duration (0.5–1s) then kill the process
4. Extract frame
   - ffmpeg -y -i "$MEDNAFEN_HOME/rec.mov" -ss 0 -frames:v 1 path/to/output.png
5. Upload artifact
   - Use your CI system's artifact upload step to persist the PNG

Alternative (xdotool snapshot)
- Instead of `-qtrecord`, start mednafen and use `xdotool` to send F9 (snapshot) to the mednafen window. Snapshots are saved to MEDNAFEN_HOME/snaps/ by default.
- This requires a running X server and a window manager; it may be more flaky than recording+ffmpeg.

Sample GitHub Actions job (sketch)

```yaml
jobs:
  build-and-snapshot:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y cc65 mednafen xvfb xdotool ffmpeg
      - name: Build ROM
        run: make -C nes-ide/examples/hello-world
      - name: Start Xvfb
        run: |
          Xvfb :99 -screen 0 640x480x24 &
          echo $! > xvfb.pid
          export DISPLAY=:99
      - name: Run Mednafen (record)
        run: |
          MEDNAFEN_HOME=$(mktemp -d)
          export MEDNAFEN_HOME
          mednafen -qtrecord "$MEDNAFEN_HOME/rec.mov" nes-ide/examples/hello-world/hello.nes &> "$MEDNAFEN_HOME/mednafen.log" &
          MF_PID=$!
          sleep 1
          kill $MF_PID || true
      - name: Extract frame
        run: |
          ffmpeg -y -i "$MEDNAFEN_HOME/rec.mov" -ss 0 -frames:v 1 nes-ide/examples/hello-world/mednafen_ci_snapshot.png || true
      - name: Upload snapshot
        uses: actions/upload-artifact@v4
        with:
          name: nes-hello-snapshot
          path: nes-ide/examples/hello-world/mednafen_ci_snapshot.png
```

Caveats and tips
- Mednafen binary packages vary by distro; ensure the installed mednafen supports `-qtrecord` and that it can start without trying to open the host audio device in a way that blocks.
- Recording may require non-blocking audio sinks; use `apulse` or dummy sinks if needed in CI.
- If mednafen fails to open a display or GFX backend, check `MEDNAFEN_HOME/mednafen.log` for diagnostics.
- The `xdotool` approach requires a window manager; using `-qtrecord` tends to be more reliable in headless CI.

Notes on verification
- I included `nes-ide/tools/build_and_snapshot_ci.sh` in the repo as a best-effort script that attempts the above when `Xvfb` and `ffmpeg` are present. It will exit with non-zero on missing deps and logs to `$MEDNAFEN_HOME` when running.

If you'd like, I can also:
- Commit a ready-to-run GitHub Actions workflow file under `.github/workflows/` that implements the sketch above.
- Adapt the workflow to test multiple examples and run on matrix (e.g., different mednafen versions).

---

CI workflow added: `.github/workflows/ci.yml` builds the example and attempts headless capture. Artifacts are uploaded from `nes-ide/artifacts/`.

