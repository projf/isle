# Isle.Computer - Lakritz Makefile
# Copyright Isle Authors
# SPDX-License-Identifier: MIT

# FPGA IC
FPGA_TYPE = 25k  # 25k for Lakrizt
FPGA_PKG = CABGA256  # CABGA256 for Lakritz

# configuration
SHELL = /bin/sh
FPGA_SPEED = 8     # FPGA speed grade (6,7,8) - all parts seem fine with fastest
LPF = lakritz.lpf  # constraints
TARGET_FREQ = 25   # target frequency (MHz)

# included Verilog modules
PATH_LIB = ../../hardware
ADD_SRC += ${PATH_LIB}/book/ch01/ch01_pattern.v
ADD_SRC += ${PATH_LIB}/book/ch01/ch01_square.v
ADD_SRC += ${PATH_LIB}/gfx/display.v
ADD_SRC += ${PATH_LIB}/gfx/tmds_encoder.v
# ecp5 arch modules
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock2_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/dvi_generator.v

ch01: ch01.bit ch01.svf

# synthesis
%.json: top_%.v $(ADD_SRC)
	yosys -ql $(basename $@)-yosys.log -p 'synth_ecp5 -top top_$(basename $@) -json $@' $< $(ADD_SRC)

# place and route
%.config: %.json
	nextpnr-ecp5 --randomize-seed --${FPGA_TYPE} --package ${FPGA_PKG} --freq ${TARGET_FREQ} --speed ${FPGA_SPEED} --json $< --textcfg $@ --lpf ${LPF}

# pack bitstream
%.bit: %.config
	ecppack --compress $< $@

# pack SVF (Serial Vector Format)
%.svf: %.config
	ecppack --compress --input $< --svf $@

all: ch01

clean:
	rm -f *.json *.config *.bit .*.d *.svf *yosys.log

.PHONY: all clean
