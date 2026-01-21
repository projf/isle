# Isle.Computer - Verilator Makefile (Chapter 5)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../verilator.mk

PATH_LIB  = ../../../hardware
PATH_PROJ = ../../../projects

# Common Verilog
VERILOG_LIBS += -I${PATH_LIB}/book/ch05
VERILOG_LIBS += -I${PATH_LIB}/gfx
VERILOG_LIBS += -I${PATH_LIB}/mem
VERILOG_LIBS += -I${PATH_LIB}/sys


ch05: ch05.exe

all: ch05

clean:
	rm -rf ./obj_dir

.PHONY: all clean
