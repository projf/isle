# Isle.Computer - Verilator Makefile Include
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

VFLAGS = -O3 --x-assign fast --x-initial fast --noassert --stats
CFLAGS = -std=c++17
SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS = `sdl2-config --libs`
OPT_FLAGS = -O3 -march=native -mtune=native -flto
# VERILOG_DEBUG = -DDEBUG

# synthesis (secondary expansion because VERILOG_LIBS is set after rule)
.SECONDEXPANSION:
%.mk: top_%.v
	verilator ${VFLAGS} -I.. ${VERILOG_LIBS} \
	    -cc $< --exe main_$(basename $@).cpp -o $(basename $@) $(VERILOG_DEBUG) \
		-I.. -CFLAGS "${CFLAGS} ${SDL_CFLAGS} ${OPT_FLAGS}" -LDFLAGS "${SDL_LDFLAGS} ${OPT_FLAGS}"

%.exe: %.mk
	make -C ./obj_dir -f Vtop_$< OPT_FAST="$(OPT_FLAGS)"
