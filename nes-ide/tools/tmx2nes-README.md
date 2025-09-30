# tmx2snes / tmx2nes — Tiled → NES nametable guidance

What it does (SNES):
- `tmx2snes` converts Tiled TMX maps into SNES-friendly formats (tile indexes, tilemaps, palettes, and possibly layering metadata).

NES differences and challenges:
- NES nametables are 32x30 tiles with attribute tables that pack palette information in 2x2 tile blocks (2 bits per block). Mirroring and scrolling also affect layout.
- The SNES pipeline supports larger palettes and more flexible tile sizes and layers; NES needs strict adherence to nametable dimensions and attribute packing.

Export strategy for NES:
- Use Tiled to design levels in 8x8 tiles. Create a small exporter (`tmx2nes.py`) that:
  - Generates CHR references for tiles used in the map.
  - Emits a nametable array (32x30) in a `.inc` or `.o` file for inclusion.
  - Computes the attribute table (64 bytes) by packing 2x2 tile blocks into 2-bit palette selections.
  - Handles horizontal/vertical mirroring considerations.

Recommended tools and references:
- Tiled (https://www.mapeditor.org/)
- Examples of TMX → NES exporters in various repos (community scripts)

Suggested next step: add `tools/tmx2nes.py` placeholder and short README linking to sample scripts.
