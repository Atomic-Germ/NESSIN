/* Minimal NES hardware helpers (PPU access) */

#include "nes.h"

/* Write a block to PPU VRAM using PPUADDR/PPUDATA macros from the header */
void ppu_write_vram(unsigned short addr, const unsigned char* data, unsigned short len) {
    /* Set VRAM address (high then low) */
    PPUADDR = (unsigned char)((addr >> 8) & 0xFF);
    PPUADDR = (unsigned char)(addr & 0xFF);
    while (len--) {
        PPUDATA = *data++;
    }
}

void pal_bg(unsigned char value) {
    unsigned char pal[8] = { 0x00, 0x01, 0x11, 0x21, 0x0F, 0x16, 0x26, 0x36 };
    pal[0] = value;
    ppu_write_vram(0x3F00, pal, 8);
}

void ppu_wait_nmi(void) {
    while (!(PPUSTATUS & 0x80)) {
        /* spin */
    }
}

