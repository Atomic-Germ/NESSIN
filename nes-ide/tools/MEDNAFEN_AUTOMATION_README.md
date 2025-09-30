<!-- markdownlint-disable-file -->
# Mednafen automation: Automated short recording + snapshot (Option B)

This folder contains a small macOS automation script that runs Mednafen, starts/stops a short recording via the in-emulator "record movie" command, takes a snapshot, and exits. It uses AppleScript (osascript) to send key events to the Mednafen process.

Files added
- `mednafen_auto_movie_snapshot.sh` — zsh script that:
  - starts Mednafen with a clean `MEDNAFEN_HOME` (temp directory),
  - uses AppleScript to send SHIFT+F5 (start movie), F9 (snapshot), SHIFT+F5 (stop movie), and F12 (exit),
  - copies the latest PNG snapshot to repository root as `mednafen_snapshot.png` when found,
  - leaves the `MEDNAFEN_HOME` directory in place for inspection.

How it works / constraints

- This script is macOS-focused and requires `osascript` (AppleScript) to send keystrokes to the Mednafen window. It runs Mednafen in the background and attempts to activate the Mednafen process before sending keys.
- It is not fully headless — it simulates GUI keystrokes. Run this on a logged-in macOS session.
- The script avoids permanently deleting the temporary `MEDNAFEN_HOME` so you can inspect generated `snaps/` and `mcm/` files. Remove it manually when done.

Prerequisites
- `mednafen` installed and on PATH (homebrew: `brew install mednafen`)
- `osascript` (built-in on macOS)
- Optional: `ffmpeg` if you want to extract frames from recorded movies (`brew install ffmpeg`)

Usage

1) Make the script executable:

```zsh
chmod +x nes-ide/tools/mednafen_auto_movie_snapshot.sh
```

2) Run it with an absolute path to your built ROM (example from the repo):

```zsh
./nes-ide/tools/mednafen_auto_movie_snapshot.sh /absolute/path/to/NESSIN/nes-ide/examples/hello-world/hello.nes
```

After the script finishes, look for `mednafen_snapshot.png` in the current working directory (copied from the temp MEDNAFEN_HOME/snaps). The MEDNAFEN_HOME path will be printed so you can inspect any generated files.

If you prefer a Linux/X11 approach, it's straightforward to adapt this script to use `xdotool` (send keys to the Mednafen window) and `Xvfb` for headless environments. Let me know and I will add a cross-platform runner.

Next steps I can take
- Convert the example to embed CHR-ROM (8KB) so the screenshot is deterministic (recommended). This avoids relying on runtime CHR uploads which some setups may not render the same way.
- Add a CI-friendly wrapper that runs Mednafen under Xvfb and extracts frames using ffmpeg (for Linux CI).
