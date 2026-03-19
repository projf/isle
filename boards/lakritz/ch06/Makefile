# Isle.Computer - Lakritz Makefile (Chapter 6)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../lakritz.mk

PATH_LIB  = ../../../hardware
PATH_PROJ = ../../../projects

# Common Verilog
ADD_SRC += ${PATH_LIB}/book/ch06/ch06.v
ADD_SRC += ${PATH_LIB}/cpu/FemtoRV32.v
ADD_SRC += ${PATH_LIB}/devs/gfx_dev.v
ADD_SRC += ${PATH_LIB}/devs/sys_dev.v
ADD_SRC += ${PATH_LIB}/devs/uart_dev.v
ADD_SRC += ${PATH_LIB}/gfx/display.v
ADD_SRC += ${PATH_LIB}/gfx/font_glyph.v
ADD_SRC += ${PATH_LIB}/gfx/textmode.v
ADD_SRC += ${PATH_LIB}/gfx/tmds_encoder.v
ADD_SRC += ${PATH_LIB}/io/uart_rx.v
ADD_SRC += ${PATH_LIB}/math/lfsr.v
ADD_SRC += ${PATH_LIB}/mem/clut.v
ADD_SRC += ${PATH_LIB}/mem/fifo_sync.v
ADD_SRC += ${PATH_LIB}/mem/rom_sync.v
ADD_SRC += ${PATH_LIB}/mem/sysram.v
ADD_SRC += ${PATH_LIB}/mem/tram.v
ADD_SRC += ${PATH_LIB}/sys/xd.v

# ECP5 Arch
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock2_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/dvi_generator.v


ch06: ch06.bit ch06.svf

all: ch06

clean:
	rm -f *.json *.config *.bit .*.d *.svf *yosys.log

.PHONY: all clean
