# Isle.Computer - Assembler Makefile (Chapter 6)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

MAKEFLAGS += --no-builtin-rules --no-builtin-variables

# BIN_PREFIX needs adjusting on some platforms
#  e.g. riscv64-elf on Arch Linux and riscv64-linux-gnu on Fedora
BIN_PREFIX := riscv64-unknown-elf

# arch settings
MARCH := rv32im
MABI  := ilp32

# linker script
LDSCRIPT := isle16.ld

# derive tool names from prefix
AS      := $(BIN_PREFIX)-as
AR      := $(BIN_PREFIX)-ar
LD      := $(BIN_PREFIX)-ld
OBJDUMP := $(BIN_PREFIX)-objdump
OBJCOPY := $(BIN_PREFIX)-objcopy
HEXDUMP := hexdump

# find sources (includes from current directory)
LIB_SRCS := $(wildcard lib/*.s)
LIB_OBJS := $(LIB_SRCS:.s=.o)
INCS     := $(wildcard include/*.inc)
SRCS     := $(wildcard *.s)
MEMS     := $(SRCS:.s=.mem)
NAMES    := $(SRCS:.s=)

# lib archive
LIB_ISLE := lib/libisle.a

#
# targets
#

all: $(MEMS)

# allow 'make hello' to build hello.mem
$(NAMES): %: %.mem

# assemble
%.o: %.s $(INCS)
	$(AS) -march=$(MARCH) -mabi=$(MABI) $< -o $@

# create static archive
$(LIB_ISLE): $(LIB_OBJS)
	$(AR) rcs $@ $^

# auto-delete lib object files after archive creation
.INTERMEDIATE: $(LIB_OBJS)

# link
%.out: %.o $(LIB_ISLE)
	$(LD) $< $(LIB_ISLE) -o $@ -T $(LDSCRIPT) -m elf32lriscv -nostdlib

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
	rm -f *.o lib/*.o *.out *.bin *.mem *.dis $(LIB_ISLE)

.PHONY: all clean $(NAMES)
