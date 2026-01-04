# Isle.Computer - Canvas Display AGU Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

SIM ?= icarus
TOPLEVEL_LANG ?= verilog
DUT = canv_disp_agu

TOPLEVEL = ${DUT}
COCOTB_TEST_MODULES = ${DUT}
HARDWARE = $(PWD)/../..

VERILOG_SOURCES += $(HARDWARE)/gfx/${DUT}.v

# pass Verilog module parameters to simulator
COMPILE_ARGS += -P${DUT}.CORDW=16 -P${DUT}.WORD=32 -P${DUT}.ADDRW=8 -P${DUT}.BMAP_LAT=6 -P${DUT}.SHIFTW=3

# each test needs its own build dir and results file
COCOTB_RESULTS_FILE = results_${DUT}.xml
SIM_BUILD = sim_build/${DUT}

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
