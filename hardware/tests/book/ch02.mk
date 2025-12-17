# Isle.Computer - Chapter 2 Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

SIM ?= icarus
TOPLEVEL_LANG ?= verilog
DUT = ch02

MODULE = ${DUT}
TOPLEVEL = ${DUT}
HARDWARE = $(PWD)/../..

VERILOG_SOURCES += $(HARDWARE)/book/${DUT}/${DUT}.v
VERILOG_SOURCES += $(HARDWARE)/gfx/canv_disp_agu.v
VERILOG_SOURCES += $(HARDWARE)/gfx/display.v
VERILOG_SOURCES += $(HARDWARE)/mem/clut.v
VERILOG_SOURCES += $(HARDWARE)/mem/vram.v

# pass Verilog module parameters to simulator
COMPILE_ARGS += -P${DUT}.DISPLAY_MODE=3
COMPILE_ARGS += -P${DUT}.FILE_BMAP="\"../../../res/bitmaps/latency/latency-672x384.mem"\"
COMPILE_ARGS += -P${DUT}.FILE_PAL="\"../../../res/bitmaps/latency/latency-672x384_palette.mem"\"
COMPILE_ARGS += -P${DUT}.CANV_BPP=2
COMPILE_ARGS += -P${DUT}.CANV_SCALE=16\'d1
COMPILE_ARGS += -P${DUT}.WIN_WIDTH=16\'d672
COMPILE_ARGS += -P${DUT}.WIN_HEIGHT=16\'d384
COMPILE_ARGS += -P${DUT}.WIN_STARTX=16\'d0

# each test needs its own build dir and results file
COCOTB_RESULTS_FILE = results_${DUT}.xml
SIM_BUILD = sim_build/${DUT}

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
