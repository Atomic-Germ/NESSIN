#!/usr/bin/env make
TARGET = hello
SRC = src/main.c src/nes_stubs.c

PRG_BIN = $(TARGET).prg
CHR_BIN = $(TARGET).chr
INES = $(TARGET).nes

all: $(INES)

clean:
	rm -f $(INES) $(PRG_BIN) $(CHR_BIN)


# Create an 8KB CHR image: populate first tile with our pattern, rest zeros
$(CHR_BIN):
	# Create a simple 8KB CHR with the first 16 bytes set to the demo tile
	# Write the 16-byte pattern then pad to 8192 bytes
	printf '\xFF\x00\xFF\x00\xFF\x00\xFF\x00\x00\xFF\x00\xFF\x00\xFF\x00\xFF' > $(CHR_BIN)
	dd if=/dev/zero bs=1 count=$$((8192 - 16)) >> $(CHR_BIN) 2>/dev/null || true

# Build final iNES by linking with cl65 then replacing/embedding CHR (keeps PRG size as produced)
$(INES): $(SRC) $(CHR_BIN)
	cl65 -t nes -o $(TARGET).tmp.nes $(SRC)
	# Read PRG bank count from tmp.nes header (byte 4)
	hex=$$(xxd -p -s 4 -l1 $(TARGET).tmp.nes)
	prg_banks=$$((0x$${hex}))
	# Build header (NES 0x1A, PRG count, CHR count = 1, flags 6-15 = 0)
	prg_hex=$$(printf '%02x' $$prg_banks)
	# header hex: 4e45531a + prg_hex + chr=01 + 10 bytes zeros
	zeros=$$(printf '%020s' | tr ' ' '0')
	header_hex="4e45531a$${prg_hex}01$${zeros}"
	echo "$${header_hex}" | xxd -r -p > $(INES)
	# Append PRG (skip 16-byte header) and our CHR
	# Use tail to copy everything after the 16-byte iNES header reliably
	tail -c +17 $(TARGET).tmp.nes >> $(INES) 2>/dev/null || true
	cat $(CHR_BIN) >> $(INES)
	rm -f $(TARGET).tmp.nes

.PHONY: all clean
