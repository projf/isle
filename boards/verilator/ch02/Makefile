# Isle.Computer - Verilator Makefile (Chapter 2)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../verilator.mk

PATH_LIB  = ../../../hardware
PATH_PROJ = ../../../projects

# Common Verilog
VERILOG_LIBS += -I${PATH_LIB}/book/ch02
VERILOG_LIBS += -I${PATH_LIB}/gfx
VERILOG_LIBS += -I${PATH_LIB}/mem


ch02: ch02.exe

all: ch02

clean:
	rm -rf ./obj_dir

.PHONY: all clean
