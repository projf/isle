# Isle.Computer - Verilator Makefile (Chapter 2)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

include ../verilator.mk

# Verilog modules
PATH_LIB = ../../../hardware
VERILOG_LIBS += -I${PATH_LIB}/book/ch02
VERILOG_LIBS += -I${PATH_LIB}/gfx
VERILOG_LIBS += -I${PATH_LIB}/mem

ch01: ch02.exe

all: ch02

clean:
	rm -rf ./obj_dir

.PHONY: all clean
