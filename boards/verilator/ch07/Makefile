# Isle.Computer - Verilator Makefile (Chapter 7)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../verilator.mk

PATH_LIB  = ../../../hardware
PATH_INCLUDE = ${PATH_LIB}/include
PATH_PROJ = ../../../projects

# Common Verilog
VERILOG_LIBS += -I${PATH_LIB}/book/ch07
VERILOG_LIBS += -I${PATH_LIB}/cpu
VERILOG_LIBS += -I${PATH_LIB}/devs
VERILOG_LIBS += -I${PATH_LIB}/gfx
VERILOG_LIBS += -I${PATH_LIB}/io
VERILOG_LIBS += -I${PATH_LIB}/math
VERILOG_LIBS += -I${PATH_LIB}/mem
VERILOG_LIBS += -I${PATH_LIB}/sys
VERILOG_LIBS += -I${PATH_INCLUDE}


ch07: ch07.exe

all: ch07

clean:
	rm -rf ./obj_dir

.PHONY: all clean
