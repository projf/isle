# Isle.Computer - Verilator Makefile (Chapter 1)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../verilator.mk

PATH_LIB  = ../../../hardware
PATH_PROJ = ../../../projects

# Common Verilog
VERILOG_LIBS += -I${PATH_LIB}/book/ch01
VERILOG_LIBS += -I${PATH_LIB}/gfx

# Project: Hitomezashi
VERILOG_LIBS += -I${PATH_PROJ}/hitomezashi

# Project: Starfield
VERILOG_LIBS += -I${PATH_PROJ}/starfield
VERILOG_LIBS += -I${PATH_LIB}/math


ch01: ch01.exe

all: ch01

clean:
	rm -rf ./obj_dir

.PHONY: all clean
