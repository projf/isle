# Isle.Computer - Chapter 1 Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

SIM ?= icarus
TOPLEVEL_LANG ?= verilog

DUT = ch01
VERILOG_SOURCES += $(PWD)/../${DUT}/${DUT}.v $(PWD)/../../gfx/display.v
TOPLEVEL = ${DUT}
MODULE = ch01

# pass Verilog module parameters to simulator
COMPILE_ARGS += -P${DUT}.DISPLAY_MODE=0

# each test needs its own build dir and results file
COCOTB_RESULTS_FILE = results_${DUT}.xml
SIM_BUILD = sim_build/${DUT}

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
