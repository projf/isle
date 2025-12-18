# Isle.Computer - Chapter 4 Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

SIM ?= icarus
TOPLEVEL_LANG ?= verilog
DUT = ch04

TOPLEVEL = ${DUT}
MODULE = ${DUT}
HARDWARE = $(PWD)/../..

VERILOG_SOURCES += $(HARDWARE)/book/${DUT}/${DUT}.v
VERILOG_SOURCES += $(HARDWARE)/gfx/display.v
VERILOG_SOURCES += $(HARDWARE)/gfx/font_glyph.v
VERILOG_SOURCES += $(HARDWARE)/gfx/textmode.v
VERILOG_SOURCES += $(HARDWARE)/mem/clut.v
VERILOG_SOURCES += $(HARDWARE)/mem/rom_sync.v
VERILOG_SOURCES += $(HARDWARE)/mem/tram.v

# pass Verilog module parameters to simulator
COMPILE_ARGS += -P${DUT}.DISPLAY_MODE=3
COMPILE_ARGS += -P${DUT}.FILE_FONT="\"../../../res/fonts/unifont-rom.mem"\"
COMPILE_ARGS += -P${DUT}.FILE_PAL="\"../../../res/palettes/go-16.mem"\"
COMPILE_ARGS += -P${DUT}.FILE_TXT="\"../../../res/textmaps/edge-84x24.mem"\"
COMPILE_ARGS += -P${DUT}.FONT_COUNT=128
COMPILE_ARGS += -P${DUT}.GLYPH_HEIGHT=16
COMPILE_ARGS += -P${DUT}.GLYPH_WIDTH=8
COMPILE_ARGS += -P${DUT}.TEXT_SCALE=32\'h00010001
COMPILE_ARGS += -P${DUT}.WIN_START=32\'h00000000
COMPILE_ARGS += -P${DUT}.WIN_END=32\'h018002A0

# each test needs its own build dir and results file
COCOTB_RESULTS_FILE = results_${DUT}.xml
SIM_BUILD = sim_build/${DUT}

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
