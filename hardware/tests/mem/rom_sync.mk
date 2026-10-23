# Isle.Computer - Synchronous ROM Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

SIM ?= icarus
TOPLEVEL_LANG ?= verilog
DUT = rom_sync

TOPLEVEL = ${DUT}
COCOTB_TEST_MODULES = ${DUT}
HARDWARE = $(PWD)/../..

VERILOG_SOURCES += $(HARDWARE)/mem/${DUT}.v
INIT_FILE ?= rom_sync_init.mem
export INIT_FILE

# pass Verilog module parameters to simulator
COMPILE_ARGS += -P${DUT}.ADDRW=4 -P${DUT}.DATAW=8 -P${DUT}.DEPTH=16 -P${DUT}.FILE_ROM=\"${INIT_FILE}\"

# each test needs its own build dir and results file
COCOTB_RESULTS_FILE = results_${DUT}.xml
SIM_BUILD = sim_build/${DUT}

# rebuild if this makefile (including its params) changes
CUSTOM_COMPILE_DEPS += $(DUT).mk

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
