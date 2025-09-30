# NES-IDE (experimental scaffold)

This project is an experimental NES-targeted IDE scaffold inspired by SNES-IDE.
The goal: adapt the "IDE" concept and UX for NES development rather than SNES.

Important: This is deliberately a different platform (NES) with different toolchains,
APIs, and limitations. The upstream SNES-IDE uses `pvsneslib` and SNES-specific
tools; this scaffold will favor NES toolchains and libraries.

Suggested toolchain options for NES development (pick one):

- cc65 + neslib
  - cc65 (C compiler targeting 6502 family) + neslib (utility library)
  - Good for C-based NES development.
- ca65 + neslib / nesdoug-style libraries
  - ca65 (assembler from the cc65 suite) for a more assembly-first approach.
- NESASM2 / ASM6
  - Classic NES assemblers used by retro devs.

Emulator choices for testing locally:
- FCEUX, Nestopia, or Mesen (Mesen recommended for accuracy on Windows)

What I created here:
- `docs/` placeholder for NES docs and tutorials
- `assets/` placeholder for tiles/sprites/tools
- `README.md` (this file) and basic notes

Next moves I can do for you (pick any):
- Create a minimal `examples/hello-world/` with a tiny asm or C example compiled by `cc65` (I will create only source + Makefile; you'll need `cc65` installed locally to build).
- Research and write a recommended toolchain install + minimal build steps for macOS (since you're on macOS zsh).
- Add an opinionated choice (I can pick cc65+neslib and create an example project and build script).

Which should I do next? If you want me to proceed with building a minimal example, say which toolchain you prefer (cc65/neslib recommended).