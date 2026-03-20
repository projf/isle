# Isle.Computer - Verilator Makefile (Chapter 6)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../verilator.mk

PATH_LIB  = ../../../hardware
PATH_PROJ = ../../../projects

# Common Verilog
VERILOG_LIBS += -I${PATH_LIB}/book/ch06
VERILOG_LIBS += -I${PATH_LIB}/cpu
VERILOG_LIBS += -I${PATH_LIB}/devs
VERILOG_LIBS += -I${PATH_LIB}/gfx
VERILOG_LIBS += -I${PATH_LIB}/io
VERILOG_LIBS += -I${PATH_LIB}/math
VERILOG_LIBS += -I${PATH_LIB}/mem
VERILOG_LIBS += -I${PATH_LIB}/sys


ch06: ch06.exe

all: ch06

clean:
	rm -rf ./obj_dir

.PHONY: all clean
