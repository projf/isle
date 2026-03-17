# Isle.Computer - UART TX Test Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

SIM ?= icarus
TOPLEVEL_LANG ?= verilog
DUT = uart_tx

TOPLEVEL = ${DUT}
COCOTB_TEST_MODULES = ${DUT}
HARDWARE = $(PWD)/../..

VERILOG_SOURCES += $(HARDWARE)/io/${DUT}.v

# pass Verilog module parameters to simulator
COMPILE_ARGS += -P${DUT}.UART_CNT_W=16 -P${DUT}.UART_CNT_INC=503 -P${DUT}.UART_DATAW=8

# each test needs its own build dir and results file
COCOTB_RESULTS_FILE = results_${DUT}.xml
SIM_BUILD = sim_build/${DUT}

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
