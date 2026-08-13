# Isle.Computer - ULX3S Makefile (Chapter 7)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../ulx3s.mk

PATH_LIB  = ../../../hardware
PATH_INCLUDE = ${PATH_LIB}/include
PATH_PROJ = ../../../projects

# Common Verilog
ADD_SRC += ${PATH_LIB}/book/ch07/ch07.v
ADD_SRC += ${PATH_LIB}/cpu/FemtoRV32.v
ADD_SRC += ${PATH_LIB}/devs/dev_display.v
ADD_SRC += ${PATH_LIB}/devs/dev_earthrise.v
ADD_SRC += ${PATH_LIB}/devs/dev_sys.v
ADD_SRC += ${PATH_LIB}/devs/dev_uart.v
ADD_SRC += ${PATH_LIB}/gfx/canv_disp_agu.v
ADD_SRC += ${PATH_LIB}/gfx/canv_draw_agu.v
ADD_SRC += ${PATH_LIB}/gfx/circle.v
ADD_SRC += ${PATH_LIB}/gfx/display_sync_gen.v
ADD_SRC += ${PATH_LIB}/gfx/earthrise.v
ADD_SRC += ${PATH_LIB}/gfx/fline.v
ADD_SRC += ${PATH_LIB}/gfx/font_glyph.v
ADD_SRC += ${PATH_LIB}/gfx/line.v
ADD_SRC += ${PATH_LIB}/gfx/textmode.v
ADD_SRC += ${PATH_LIB}/gfx/tmds_encoder.v
ADD_SRC += ${PATH_LIB}/io/uart_rx.v
ADD_SRC += ${PATH_LIB}/math/lfsr.v
ADD_SRC += ${PATH_LIB}/mem/clut.v
ADD_SRC += ${PATH_LIB}/mem/erlist.v
ADD_SRC += ${PATH_LIB}/mem/fifo_sync.v
ADD_SRC += ${PATH_LIB}/mem/rom_sync.v
ADD_SRC += ${PATH_LIB}/mem/sysram.v
ADD_SRC += ${PATH_LIB}/mem/tram.v
ADD_SRC += ${PATH_LIB}/mem/vram.v
ADD_SRC += ${PATH_LIB}/sys/xd.v

# ECP5 Arch
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock2_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/dvi_generator.v


ch07: ch07.bit ch07.svf

all: ch07

clean:
	rm -f *.json *.config *.bit .*.d *.svf *yosys.log

.PHONY: all clean
