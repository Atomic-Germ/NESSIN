<!-- markdownlint-disable-file -->
# SNES-IDE / PVSNESLIB tools → NES equivalents

This document maps the primary tools bundled with SNES-IDE (and the pvsneslib toolset) to NES-equivalent tools where possible. For each SNES tool or capability, I list the SNES tool, its purpose, an NES tool with the closest functional parity, and notes about gaps or recommended README replacements when no close equivalent exists.

---

## Mapping summary (high-level)

- Compiler / Assembler: 816-tcc, wla-dx (65816) → cc65 / ca65 (6502)
- Asset converters (graphics, tiles, palettes): snesbrr, gfx4snes, pcx2snes, smconv → NES Screen Tool, Tile Layer Pro, png2chr (various), NESHLA tools
- Audio tools (SPC/BRR conversion, trackers): snesgss / snesbrr → Famitracker, NSF tools, repl. audio pipeline for NES (DMC/2A03) with FamiTracker export
- Map/tile tools: tmx2snes, tilesetextractor → Tiled + nes2tmx/nes tools or custom scripts; NES Screen Tool for maps and nametables
- Emulation / testing: bsnes → Mesen / FCEUX
- Library: pvsneslib (C runtime & helpers) → neslib (C/assembly helpers) + libnes / cc65 runtime

---

## Detailed mapping

### 1) Compiler & assembler

- SNES: 816-tcc (tcc fork for 65816), wla-dx (assembler/linker supporting 65816)
  - Purpose: compile C and assemble 65816 assembly into SNES ROMs; linked into an SNES-target ROM image.
- NES equivalent: cc65 (cc65/ca65 + ld65)
  - Purpose: a complete 6502/6507/6502-family cross-development toolchain with C compiler, assembler (ca65), linker (ld65) and runtime libraries.
  - Notes: cc65 is the canonical modern choice for C on the NES. It has a mature runtime and many community examples. cc65 lacks built-in tools for some NES-specific binary packing that SNES toolchains include, but the community provides scripts and makefiles.

When to use: choose `cc65` when you want to write C and/or assembly and produce .nes ROMs. Where SNES-IDE uses `816-tcc` + pvsneslib C headers, use `cc65` + `neslib` or `libnes` equivalents.

---

### 2) Assembler-only and linker (WLA-DX parity)

- SNES: wla-dx
  - Purpose: multi-target assembler (supports many architectures), used by pvsneslib toolchains to assemble ASM sources and link.
- NES equivalent: ca65 (part of cc65) or **WLA-DX can already target 6502**.
  - Purpose: ca65 is the direct assembler in the cc65 suite. Alternatively, WLA-DX itself supports 6502 and can be reused; however, cc65/ca65 is more commonly used in NES workflows.
  - Notes: If a project already uses WLA-DX macros or a wla toolchain, it's feasible to keep WLA-DX for NES since it supports 6502; but most NES projects prefer cc65/ca65 for C integrations.

---

### 3) Graphics / tile converters

- SNES tools: `gfx4snes.exe`, `pcx2snes`, `tilesetextractor`, `tmx2snes` (map/tiles pipeline)
  - Purpose: convert PC images (PCX/PNG/TGA) to SNES-friendly tile/planar formats, build palettes, and generate CHR-like binary data for SNES VRAM layers.
- NES equivalents / replacements:
  - NES Screen Tool (Shiru) — GUI for creating and exporting nametables, palettes, patterns (CHR) and metasprites.
  - png2chr / gfx2chr (various CLI tools) — convert PNG/TGA tiles to CHR binary data; `neslib` workflows often use `png2chr` and `tilemerger` scripts.
  - Tile Layer Pro / YY-CHR — tile editors for low-level tile editing and export.
  - Tiled + custom exporter (tmx → NES nametable) — many NES projects use Tiled to design levels and export with small scripts that produce nametables/CHR references.

Notes: The SNES pipeline handles larger palettes and more complex mode layers; the NES equivalents typically operate on 8x8 tiles, 4-color palettes per tile, and explicit nametable constraints. A README describing differences and conversion hints is included below when parity is incomplete.

---

### 4) Audio and music tools

- SNES tools: `snesgss`, `snesbrr`, SPC toolchain, Schism/M8TE integrations
  - Purpose: convert audio and samples to SNES SPC bank formats, provide trackers and drivers for SNES APU or SPC700 audio.
- NES equivalents:
  - Famitracker — tracker for composing NES music with 2A03/DPCM channels; exports NSF or FamiTracker `.ftm` which can be used to generate binary data for NES games.
  - NSF tools / NSF2VGM / Blargg libs — utilities to work with NES audio formats and testing via emulators.
  - DPCM sample packers: `dmc2pcm` and `sappy`-style toolchains or `FamiTone` / `NIN` examples.

Notes: The SNES SPC system is far richer; NES has limited channels and DPCM constraints. Converting sound assets from SNES to NES is often manual and requires re-arrangement and re-sampling.

---

### 5) Map / tile tools

- SNES: `tmx2snes`, `tilesetextractor`
- NES equivalents:
  - Tiled + nes exporter scripts (common community scripts), or direct use of NES Screen Tool for nametable creation.
  - `tmx2lua` or `tmx2nes` community scripts — may need small adaptors.

When parity is partial: include README describing exporting Tiled maps to NES nametables and limitations (attribute table packing, mirroring, scroll behavior).

---

### 6) Sprite & metasprite tools

- SNES: various tools in pvsneslib's `tools/` to pack metasprites, layouts, and sprite sheets.
- NES equivalents:
  - `NES Screen Tool` supports metasprite editing and export.
  - `SpriteLib` / `NES Spritesheet` community scripts; `metasprite.py`-like scripts used with neslib.

Notes: SNES uses larger sprites and different priorities; documentation should explain differences (64x64 vs 8x8 chunks) and how to adapt.

---

### 7) Compression / constants / optimizers

- SNES tools: `constify.exe`, `816-opt.exe` (optimizers), `snestools.exe` (collection)
- NES equivalents:
  - `asm-utils`, `nerd` scripts, and general-purpose compression tools (e.g., `lz4`, `lz77` variants) used in NES ROM hacking.
  - For constant extraction/optimization, NES projects use custom scripts or `constify` ports if available.

If no direct parity: include a README describing the purpose (optimize code/data, collapse constants into tables) and recommend possible community tools or a simple Python script replacement.

---

### 8) ROM builder & emulator integration

- SNES: `bsnes` integration and `create-new-project` scripts that build .sfc ROMs and launch bsnes.
- NES equivalents:
  - `make` + `cc65` toolchain to build `.nes` ROMs (.nes na) and `Mesen`/`FCEUX` to run them.
  - Provide a Makefile template and a one-click script to launch emulator with the built ROM.

---

## Files to add to `nes-ide/tools/` (README replacements)

For SNES tools without a direct NES equivalent, include short READMEs describing the tool and suggested replacement or minimal reimplementation notes. Create the following README placeholders:

- `constify-README.md` — explains what `constify.exe` does and how to approximate it with a Python script that collects repeated constants into a table for 6502.
- `816-opt-README.md` — documents the optimizer's goal (816-specific peephole optimizations) and suggests `asm-peep` or manual optimizations as replacement; include a simple `optimize_asm.py` example.
- `snesbrr-README.md` — describes SNES BRR sample packing and notes that NES DPCM is different; suggests using `dmcpack` or `famitracker`'s DPCM exporter for NES.
- `tmx2nes-README.md` — mapping guide for exporting Tiled TMX maps into NES nametable + attribute packing.

---

## Next steps I will take (unless you prefer otherwise):

1. Add `nes-ide/tools/TOOL_MAPPING.md` (this file) to the workspace. (Done)
2. Create README placeholders for the tools listed in "Files to add" above in `nes-ide/tools/` as small markdown files describing purpose and suggested NES workflows. (next)
3. Optionally create a minimal `nes-ide/examples/hello-world/` using `cc65` + `neslib` to demonstrate the build and emulator flow.

---

If you'd like, I can now create the README placeholder files in `nes-ide/tools/` and then scaffold `nes-ide/examples/hello-world/` with a working Makefile using `cc65` and a tiny C example. Which should I do next?