# Isle.Computer - Verilator Makefile (Chapter 1)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../verilator.mk

# Verilog modules
PATH_LIB = ../../../hardware
VERILOG_LIBS += -I${PATH_LIB}/book/ch01
VERILOG_LIBS += -I${PATH_LIB}/gfx

ch01: ch01.exe

all: ch01

clean:
	rm -rf ./obj_dir

.PHONY: all clean
