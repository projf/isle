# Isle.Computer - Lakritz Makefile (Chapter 5)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../lakritz.mk

PATH_LIB  = ../../../hardware
PATH_PROJ = ../../../projects

# Common Verilog
ADD_SRC += ${PATH_LIB}/book/ch05/ch05.v
ADD_SRC += ${PATH_LIB}/book/ch05/FemtoRV32.v
ADD_SRC += ${PATH_LIB}/gfx/display.v
ADD_SRC += ${PATH_LIB}/gfx/font_glyph.v
ADD_SRC += ${PATH_LIB}/gfx/textmode.v
ADD_SRC += ${PATH_LIB}/gfx/tmds_encoder.v
ADD_SRC += ${PATH_LIB}/mem/clut.v
ADD_SRC += ${PATH_LIB}/mem/rom_sync.v
ADD_SRC += ${PATH_LIB}/mem/sysram.v
ADD_SRC += ${PATH_LIB}/mem/tram.v
ADD_SRC += ${PATH_LIB}/sys/xd.v

# ECP5 Arch
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock2_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/dvi_generator.v


ch05: ch05.bit ch05.svf

all: ch05

clean:
	rm -f *.json *.config *.bit .*.d *.svf *yosys.log

.PHONY: all clean
