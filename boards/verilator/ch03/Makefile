# Isle.Computer - Verilator Makefile (Chapter 3)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../verilator.mk

PATH_LIB  = ../../../hardware
PATH_PROJ = ../../../projects

# Common Verilog
VERILOG_LIBS += -I${PATH_LIB}/book/ch03
VERILOG_LIBS += -I${PATH_LIB}/gfx
VERILOG_LIBS += -I${PATH_LIB}/mem


ch03: ch03.exe

all: ch03

clean:
	rm -rf ./obj_dir

.PHONY: all clean
