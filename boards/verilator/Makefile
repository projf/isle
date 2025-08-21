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
VERILOG_LIBS += -I../../hardware/gfx
VERILOG_LIBS += -I../../hardware/mem

ch01: ch01.exe
ch02: ch02.exe

%.exe: %.mk
	make -C ./obj_dir -f Vtop_$<

%.mk: top_%.v
	verilator ${VFLAGS} -I.. ${VERILOG_LIBS} \
	    -cc $< --exe main_$(basename $@).cpp -o $(basename $@) \
		-CFLAGS "${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}"

all: ch01 ch02

clean:
	rm -rf ./obj_dir

.PHONY: all clean
