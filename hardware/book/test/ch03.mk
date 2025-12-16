# Isle.Computer - Chapter 3 Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

SIM ?= icarus
TOPLEVEL_LANG ?= verilog

DUT = ch03
VERILOG_SOURCES += $(PWD)/../${DUT}/${DUT}.v $(PWD)/../../gfx/display.v $(PWD)/../../gfx/canv_disp_agu.v $(PWD)/../../gfx/canv_draw_agu.v $(PWD)/../../gfx/circle.v $(PWD)/../../gfx/earthrise.v $(PWD)/../../gfx/fline.v $(PWD)/../../gfx/line.v $(PWD)/../../mem/clut.v $(PWD)/../../mem/erlist.v $(PWD)/../../mem/vram.v
TOPLEVEL = ${DUT}
MODULE = ch03

# pass Verilog module parameters to simulator
COMPILE_ARGS += -P${DUT}.DISPLAY_MODE=3 -P${DUT}.CANV_BPP=2 -P${DUT}.CANV_WIDTH=16\'d672 -P${DUT}.CANV_HEIGHT=16\'d384 -P${DUT}.CANV_SCALE=16\'d1 -P${DUT}.WIN_WIDTH=16\'d672 -P${DUT}.WIN_HEIGHT=16\'d384 -P${DUT}.WIN_STARTX=16\'d0 -P${DUT}.WIN_STARTY=16\'d0 -P${DUT}.FILE_ER_LIST="\"../../../res/drawings/basic-test.mem"\" -P${DUT}.FILE_PAL="\"../../../res/palettes/aqua-4.mem"\"

# each test needs its own build dir and results file
COCOTB_RESULTS_FILE = results_${DUT}.xml
SIM_BUILD = sim_build/${DUT}

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
