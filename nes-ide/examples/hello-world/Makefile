
#!/bin/make -f
# Minimal NES example Makefile
TARGET = hello
SRC = src/main.c src/nes_stubs.c

PRG_BIN = $(TARGET).prg
CHR_BIN = $(TARGET).chr
INES = $(TARGET).nes

all: $(INES)

clean:
	rm -f $(INES) $(PRG_BIN) $(CHR_BIN) $(TARGET).tmp.nes $(INES).tmp


# Create an 8KB CHR image: three tiles then padding
# Tile 0: original checker style; Tile 1: inverted; Tile 2: solid block (sprite)
$(CHR_BIN):
	# Tile 0
	printf '\xFF\x00\xFF\x00\xFF\x00\xFF\x00\x00\xFF\x00\xFF\x00\xFF\x00\xFF' > $(CHR_BIN)
	# Tile 1 (invert planes)
	printf '\x00\xFF\x00\xFF\x00\xFF\x00\xFF\xFF\x00\xFF\x00\xFF\x00\xFF\x00' >> $(CHR_BIN)
	# Tile 2 (solid square: plane0=FF plane1=FF)
	printf '\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF' >> $(CHR_BIN)
	# Pad remainder to 8192 bytes
	dd if=/dev/zero bs=1 count=$$((8192 - 48)) >> $(CHR_BIN) 2>/dev/null || true

# Ensure the recipe runs in a single shell (zsh) so variables persist
.ONESHELL:
SHELL := /bin/zsh

$(INES): $(SRC) $(CHR_BIN)
	# Link with cl65 to create a temporary NES (contains header + PRG)
	cl65 -t nes -o $(TARGET).tmp.nes $(SRC)

	# Verify header magic from cl65 output
	magic=$$(xxd -p -l4 $(TARGET).tmp.nes | tr -d '\n'); \
	if [ "$$magic" != "4e45531a" ]; then \
		echo "Error: cl65 output missing iNES magic (found $$magic)" >&2; \
		exit 1; \
	fi

	# Copy entire tmp.nes (header + PRG) to temp output
	cp $(TARGET).tmp.nes $(INES).tmp

	# Patch CHR count byte (offset 5) to 01 if not already (use printf + dd)
	chr_flag=$$(xxd -p -s 5 -l1 $(INES).tmp); \
	if [ "$$chr_flag" != "01" ]; then \
		printf '\x01' | dd of=$(INES).tmp bs=1 seek=5 conv=notrunc 2>/dev/null; \
	fi

	# Append CHR data directly
	cat $(CHR_BIN) >> $(INES).tmp

	# Final sanity check
	first4=$$(xxd -p -l4 $(INES).tmp | tr -d '\n'); \
	if [ "$$first4" != "4e45531a" ]; then \
		echo "Error: final $(INES).tmp lost iNES header (found: $$first4)" >&2; \
		exit 1; \
	fi

	mv -f $(INES).tmp $(INES)
	rm -f $(TARGET).tmp.nes

.PHONY: all clean
