# Isle.Computer - Chapter 4 Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

SIM ?= icarus
TOPLEVEL_LANG ?= verilog

DUT = ch04
VERILOG_SOURCES += $(PWD)/../${DUT}/${DUT}.v $(PWD)/../../gfx/display.v $(PWD)/../../gfx/font_glyph.v $(PWD)/../../gfx/textmode.v $(PWD)/../../mem/clut.v $(PWD)/../../mem/rom_sync.v $(PWD)/../../mem/tram.v
TOPLEVEL = ${DUT}
MODULE = ch04

# pass Verilog module parameters to simulator
COMPILE_ARGS += -P${DUT}.DISPLAY_MODE=3 -P${DUT}.FILE_FONT="\"../../../res/fonts/system-font-rom.mem"\" -P${DUT}.FILE_PAL="\"../../../res/palette/go-16.mem"\" -P${DUT}.FILE_TXT="\"../../../res/textmode/hello-world.mem"\"

# each test needs its own build dir and results file
COCOTB_RESULTS_FILE = results_${DUT}.xml
SIM_BUILD = sim_build/${DUT}

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
