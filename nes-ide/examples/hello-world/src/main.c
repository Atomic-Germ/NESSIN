/* Minimal NES hello-world using cc65 conventions */

/* Minimal NES hello-world using cc65 conventions */

#include "nes.h"

/* A single 8x8 tile pattern (2-bit planar NES CHR format) - very simple checker */
const unsigned char chr_tile[16] = {
    0xFF,0x00, /* plane 0 */
    0xFF,0x00,
    0xFF,0x00,
    0xFF,0x00,
    0x00,0xFF, /* plane 1 */
    0x00,0xFF,
    0x00,0xFF,
    0x00,0xFF
};

void main(void) {
    unsigned short pattern_addr = 0x0000;
    unsigned short nt0 = 0x2000;
    unsigned char tile = 0x00;

    /* Wait for vblank then upload CHR and nametable */
    ppu_wait_nmi();

    /* write our tile into pattern table 0 */
    ppu_write_vram(pattern_addr, chr_tile, sizeof(chr_tile));

    /* Set a simple background palette and enable background rendering */
    pal_bg(0x0F);
    PPUMASK = 0x08; /* enable background */
    PPUCTRL = 0x00; /* no NMI, name table 0 */

    /* Write a single tile index into nametable 0 at (0,0) */
    ppu_write_vram(nt0, &tile, 1);

    while (1) {
        ppu_wait_nmi();
    }
}
