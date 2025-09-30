# NES Hello World (cc65 + neslib)

This example demonstrates a minimal NES project using `cc65` (C compiler) and `neslib` style conventions. It produces a `.nes` ROM you can run in Mesen or FCEUX.

Files:
- `src/main.c` — tiny C program that sets a background color and prints "HELLO" using `neslib` text routines (or a minimal fallback).
- `Makefile` — builds using `cc65`/`ca65`/`ld65` if installed.
- `assets/` — placeholder for CHR/PNG tiles and palette data.

Build (if you have cc65 installed):

```sh
make -C nes-ide/examples/hello-world
```

Run in Mesen:

```sh
mesen nes-ide/examples/hello-world/hello.nes
```

If `cc65` is not installed, the Makefile will fail — see `https://cc65.github.io/` for install instructions.
