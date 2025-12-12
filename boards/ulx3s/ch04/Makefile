# Isle.Computer - ULX3S Makefile (Chapter 4)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../ulx3s.mk

# included Verilog modules
PATH_LIB = ../../../hardware
ADD_SRC += ${PATH_LIB}/book/ch04/ch04.v
ADD_SRC += ${PATH_LIB}/gfx/display.v
ADD_SRC += ${PATH_LIB}/gfx/font_glyph.v
ADD_SRC += ${PATH_LIB}/gfx/textmode.v
ADD_SRC += ${PATH_LIB}/gfx/tmds_encoder.v
ADD_SRC += ${PATH_LIB}/mem/clut.v
ADD_SRC += ${PATH_LIB}/mem/rom_sync.v
ADD_SRC += ${PATH_LIB}/mem/tram.v
# ecp5 arch modules
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock2_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/dvi_generator.v

ch04: ch04.bit ch04.svf

all: ch04

clean:
	rm -f *.json *.config *.bit .*.d *.svf *yosys.log

.PHONY: all clean
