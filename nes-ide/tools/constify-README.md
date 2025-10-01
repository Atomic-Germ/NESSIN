# constify (SNES) — purpose and NES guidance

What it does (SNES):
- `constify` scans C/assembly sources and data to find repeated literal constants and produces optimized tables/definitions to reduce ROM size and centralize repeated data. It often helps with tight SNES memory layouts.

Why NES needs different handling:
- NES games have smaller PRG/CHR banks and more limited memory mapping. While the goal (reduce duplication) is the same, the implementation must respect 6502 addressing, bank-switching schemes, and simpler addressing modes.

NES guidance / replacement:
- Use a small Python script during the build that parses source headers and data, finds duplicate constants, and emits an assembly `.inc` with a constants table plus references.
- Alternatively, maintain duplication-aware build scripts or rely on linker optimizations from `ld65` and careful data layout.

Suggested next step: implement `tools/constify.py` (small, portable, Python 3) to provide similar functionality for NES projects.
