# 816-opt (SNES) — purpose and NES guidance

What it does (SNES):
- `816-opt` is an optimizer targeting the 65816 instruction set. It performs peephole optimizations and rewrites to reduce cycle counts or ROM size for 65816-specific sequences.

Why NES differs:
- The NES CPU is a 6502/6507 variant with different instruction encodings and addressing constraints. Many 65816-specific optimizations are not applicable.

NES guidance / replacement:
- Use small, targeted peephole rewrites for 6502 assembly. Several community scripts and tools (or a simple Python-based peephole rewriter) can be used to perform common optimizations (e.g., collapse LDA/STA pairs, strength reduction).
- Note that modern assemblers and hand-written optimized asm are often preferred for NES.

Suggested next step: provide `tools/6502-opt-README.md` with examples and a minimal `optimize_asm.py` script to demonstrate common rewrites.
