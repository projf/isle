# Isle.Computer - Verilator Makefile Include
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

VFLAGS = -O3
SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS = `sdl2-config --libs`

# synthesis (secondary expansion because VERILOG_LIBS is set after rule)
.SECONDEXPANSION:
%.mk: top_%.v
	verilator ${VFLAGS} -I.. ${VERILOG_LIBS} \
	    -cc $< --exe main_$(basename $@).cpp -o $(basename $@) \
		-CFLAGS "${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}"

%.exe: %.mk
	make -C ./obj_dir -f Vtop_$<
