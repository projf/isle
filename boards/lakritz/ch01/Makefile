# Isle.Computer - Lakritz Makefile (Chapter 1)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../lakritz.mk

PATH_LIB  = ../../../hardware
PATH_PROJ = ../../../projects

# Common Verilog
ADD_SRC += ${PATH_LIB}/book/ch01/ch01.v
ADD_SRC += ${PATH_LIB}/gfx/display.v
ADD_SRC += ${PATH_LIB}/gfx/tmds_encoder.v

# ECP5 Arch
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock2_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/dvi_generator.v

# Project: Hitomezashi
ADD_SRC += ${PATH_PROJ}/hitomezashi/hitomezashi.v

# Project: Starfield
ADD_SRC += ${PATH_PROJ}/starfield/starfield.v
ADD_SRC += ${PATH_LIB}/math/lfsr.v


ch01: ch01.bit ch01.svf

all: ch01

clean:
	rm -f *.json *.config *.bit .*.d *.svf *yosys.log

.PHONY: all clean
