# Isle.Computer - Verilator Makefile (Chapter 4)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../verilator.mk

PATH_LIB  = ../../../hardware
PATH_PROJ = ../../../projects

# Common Verilog
VERILOG_LIBS += -I${PATH_LIB}/book/ch04
VERILOG_LIBS += -I${PATH_LIB}/gfx
VERILOG_LIBS += -I${PATH_LIB}/mem


ch04: ch04.exe

all: ch04

clean:
	rm -rf ./obj_dir

.PHONY: all clean
