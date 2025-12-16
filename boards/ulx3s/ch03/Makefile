# Isle.Computer - ULX3S Makefile (Chapter 3)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../ulx3s.mk

PATH_LIB  = ../../../hardware
PATH_PROJ = ../../../projects

# Common Verilog
ADD_SRC += ${PATH_LIB}/book/ch03/ch03.v
ADD_SRC += ${PATH_LIB}/gfx/canv_disp_agu.v
ADD_SRC += ${PATH_LIB}/gfx/canv_draw_agu.v
ADD_SRC += ${PATH_LIB}/gfx/circle.v
ADD_SRC += ${PATH_LIB}/gfx/display.v
ADD_SRC += ${PATH_LIB}/gfx/earthrise.v
ADD_SRC += ${PATH_LIB}/gfx/fline.v
ADD_SRC += ${PATH_LIB}/gfx/line.v
ADD_SRC += ${PATH_LIB}/gfx/tmds_encoder.v
ADD_SRC += ${PATH_LIB}/mem/clut.v
ADD_SRC += ${PATH_LIB}/mem/erlist.v
ADD_SRC += ${PATH_LIB}/mem/vram.v

# ECP5 Arch
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock2_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/dvi_generator.v


ch03: ch03.bit ch03.svf

all: ch03

clean:
	rm -f *.json *.config *.bit .*.d *.svf *yosys.log

.PHONY: all clean
