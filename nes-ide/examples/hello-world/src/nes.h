/* Minimal nes compatibility header for example builds */
#ifndef _NES_H
#define _NES_H

/* PPU register access macros */
#define PPUCTRL  (*(volatile unsigned char*)0x2000)
#define PPUMASK  (*(volatile unsigned char*)0x2001)
#define PPUSTATUS (*(volatile unsigned char*)0x2002)
#define PPUOAMADDR (*(volatile unsigned char*)0x2003)
#define PPUOAMDATA (*(volatile unsigned char*)0x2004)
#define PPUSCROLL (*(volatile unsigned char*)0x2005)
#define PPUADDR   (*(volatile unsigned char*)0x2006)
#define PPUDATA   (*(volatile unsigned char*)0x2007)

/* Set background palette entry (writes 8 bytes to $3F00) */
void pal_bg(unsigned char value);

/* Wait for NMI / vblank (poll PPUSTATUS bit 7) */
void ppu_wait_nmi(void);

/* Write to VRAM at the given address (uses PPUADDR/PPUDATA) */
void ppu_write_vram(unsigned short addr, const unsigned char* data, unsigned short len);

#endif /* _NES_H */
