# Isle.Computer - Verilator Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

VFLAGS = -O3
SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS = `sdl2-config --libs`

# Verilog Library
VERILOG_LIBS += -I../../hardware
VERILOG_LIBS += -I../../hardware/book/ch01
VERILOG_LIBS += -I../../hardware/book/ch02
VERILOG_LIBS += -I../../hardware/book/ch03
VERILOG_LIBS += -I../../hardware/book/ch04
VERILOG_LIBS += -I../../hardware/gfx
VERILOG_LIBS += -I../../hardware/mem
VERILOG_LIBS += -I../../hardware/sys

ch01: ch01.exe
ch02: ch02.exe
ch03: ch03.exe
ch04: ch04.exe

%.exe: %.mk
	make -C ./obj_dir -f Vtop_$<

%.mk: top_%.v
	verilator ${VFLAGS} -I.. ${VERILOG_LIBS} \
	    -cc $< --exe main_$(basename $@).cpp -o $(basename $@) \
		-CFLAGS "${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}"

all: ch01 ch02 ch03 ch04

clean:
	rm -rf ./obj_dir

.PHONY: all clean
