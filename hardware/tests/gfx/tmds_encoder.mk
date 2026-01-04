# Isle.Computer - TMDS Encoder (DVI) Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

SIM ?= verilator  # requires Verilator 5.006+
TOPLEVEL_LANG ?= verilog
DUT = tmds_encoder

TOPLEVEL = ${DUT}
COCOTB_TEST_MODULES = ${DUT}
HARDWARE = $(PWD)/../..

VERILOG_SOURCES += $(HARDWARE)/gfx/${DUT}.v

# pass Verilog module parameters to simulator
COMPILE_ARGS +=

# each test Makefile needs its own build dir and results file
COCOTB_RESULTS_FILE = results_${DUT}.xml
SIM_BUILD = sim_build/${DUT}

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
