# Isle.Computer - ULX3S Makefile (Chapter 2)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../ulx3s.mk

PATH_LIB  = ../../../hardware
PATH_PROJ = ../../../projects

# Common Verilog
ADD_SRC += ${PATH_LIB}/book/ch02/ch02.v
ADD_SRC += ${PATH_LIB}/gfx/canv_disp_agu.v
ADD_SRC += ${PATH_LIB}/gfx/display.v
ADD_SRC += ${PATH_LIB}/gfx/tmds_encoder.v
ADD_SRC += ${PATH_LIB}/mem/clut.v
ADD_SRC += ${PATH_LIB}/mem/vram.v

# ECP5 Arch
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock2_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/dvi_generator.v


ch02: ch02.bit ch02.svf

all: ch02

clean:
	rm -f *.json *.config *.bit .*.d *.svf *yosys.log

.PHONY: all clean
