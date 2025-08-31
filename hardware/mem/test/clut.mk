# Isle.Computer - CLUT Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

SIM ?= icarus
TOPLEVEL_LANG ?= verilog

DUT = clut
VERILOG_SOURCES += $(PWD)/../${DUT}.v
TOPLEVEL = ${DUT}
MODULE = ${DUT}

# pass Verilog module parameters to simulator
COMPILE_ARGS += -P${DUT}.ADDRW=4 -P${DUT}.DATAW=12

# each test needs its own build dir and results file
COCOTB_RESULTS_FILE = results_${DUT}.xml
SIM_BUILD = sim_build/${DUT}

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
