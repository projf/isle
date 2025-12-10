# Isle.Computer - Verilator Makefile (Chapter 4)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../verilator.mk

# Verilog modules
PATH_LIB = ../../../hardware
VERILOG_LIBS += -I${PATH_LIB}/book/ch04
VERILOG_LIBS += -I${PATH_LIB}/gfx
VERILOG_LIBS += -I${PATH_LIB}/mem

ch03: ch04.exe

all: ch04

clean:
	rm -rf ./obj_dir

.PHONY: all clean
