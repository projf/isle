# Isle.Computer - Tram Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

SIM ?= icarus
TOPLEVEL_LANG ?= verilog
DUT = tram

TOPLEVEL = ${DUT}
COCOTB_TEST_MODULES = ${DUT}
HARDWARE = $(PWD)/../..

VERILOG_SOURCES += $(HARDWARE)/mem/${DUT}.v

# pass Verilog module parameters to simulator
COMPILE_ARGS += -P${DUT}.ADDRW=6

# each test needs its own build dir and results file
COCOTB_RESULTS_FILE = results_${DUT}.xml
SIM_BUILD = sim_build/${DUT}

# rebuild if this makefile (including its params) changes
CUSTOM_COMPILE_DEPS += $(DUT).mk

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
