# snesbrr / BRR samples — SNES vs NES audio guidance

What it does (SNES):
- `snesbrr` and related tools pack PCM samples into SNES BRR format used by the SPC700 audio subsystem.
- SNES supports high-quality sampled audio through BRR with many channels (via SPC700). Tools convert WAV/PCM into BRR frames and packing.

NES differences:
- The NES APU (2A03) has no SPC-like sample engine. It uses DPCM for sampled audio, which is much more limited (lower quality, fixed sample rates, limited size).

NES guidance / replacement:
- Use Famitracker to create music and export DPCM samples; use `dmc` packers (e.g., `dmc2wav` reversed) or `FamiTone`/`Neshla` pipelines to convert samples.
- For simple sample-conversion automation, a Python script using `scipy`/`wave` or `sox` to resample and pack DPCM frames is recommended.

Suggested next step: add `tools/dpcm-pack.py` as a small helper and reference Famitracker workflow in the project docs.
