# Isle.Computer - Assembler Makefile (Chapter 5)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

MAKEFLAGS += --no-builtin-rules --no-builtin-variables

# BIN_PREFIX may need adjusting, e.g. riscv64-elf on Arch Linux and riscv64-linux-gnu on Fedora
BIN_PREFIX := riscv64-unknown-elf

# linker script
LDSCRIPT := isle16.ld

# arch settings
MARCH := rv32i  # no compression or multiply for chapter 5
MABI  := ilp32

# tool names
AS      := $(BIN_PREFIX)-as
LD      := $(BIN_PREFIX)-ld
OBJDUMP := $(BIN_PREFIX)-objdump
OBJCOPY := $(BIN_PREFIX)-objcopy
HEXDUMP := hexdump

# find sources and derive program names and .mem targets
SRCS  := $(wildcard *.s)
NAMES := $(SRCS:.s=)
MEMS  := $(SRCS:.s=.mem)

all: $(MEMS)

# allow 'make hello' to build hello.mem
$(NAMES): %: %.mem

# assemble
%.o: %.s
	$(AS) -march=$(MARCH) -mabi=$(MABI) $< -o $@

# link
%.out: %.o
	$(LD) $< -o $@ -T $(LDSCRIPT) -m elf32lriscv -nostdlib

# generate raw binary
%.bin: %.out
	$(OBJCOPY) -O binary $< $@

# convert binary to Verilog $readmemh format
%.mem: %.bin
	$(HEXDUMP) -ve '"%08X\n"' $< > $@

# disassemble linked binary to aid with debugging
%.dis: %.out
	$(OBJDUMP) -d $< > $@

clean:
	rm -f *.o *.out *.bin *.mem *.dis

.PHONY: all clean $(NAMES)
