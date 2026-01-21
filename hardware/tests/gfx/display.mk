# Isle.Computer - Display Controller Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

SIM ?= icarus
TOPLEVEL_LANG ?= verilog
DUT = display

TOPLEVEL = ${DUT}
COCOTB_TEST_MODULES = ${DUT}
HARDWARE = $(PWD)/../..

VERILOG_SOURCES += $(HARDWARE)/gfx/${DUT}.v

# pass Verilog module parameters to simulator
COMPILE_ARGS += -P${DUT}.MODE=${DISPLAY_MODE}

# each test needs its own build dir and results file
COCOTB_RESULTS_FILE = results_${DUT}_mode_${DISPLAY_MODE}.xml
SIM_BUILD = sim_build/${DUT}_mode_${DISPLAY_MODE}

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
