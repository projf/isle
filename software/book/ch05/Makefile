# Isle.Computer - Assembler Makefile (Chapter 5)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

MAKEFLAGS += --no-builtin-rules --no-builtin-variables

# BIN_PREFIX needs adjusting on some platforms
BIN_PREFIX := riscv64-elf

# arch settings
MARCH := rv32i  # RV32I for chapter 5
MABI  := ilp32

# linker script
LDSCRIPT := isle16.ld

# tool names
AS      := $(BIN_PREFIX)-as
LD      := $(BIN_PREFIX)-ld
OBJDUMP := $(BIN_PREFIX)-objdump
OBJCOPY := $(BIN_PREFIX)-objcopy
HEXDUMP := hexdump

# check for toolchain
ifeq (,$(shell command -v $(AS) 2>/dev/null))
$(error $(AS) not found. Check your BIN_PREFIX or install a RISC-V toolchain)
endif

# find sources and derive program names and .mem targets
SRCS  := $(wildcard *.s)
NAMES := $(SRCS:.s=)
MEMS  := $(SRCS:.s=.mem)

all: $(MEMS)

#
# targets
#

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
