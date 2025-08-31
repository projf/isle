# Isle.Computer - ULX3S Makefile
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# FPGA IC
FPGA_TYPE = 85k  # 25K, 45k, or 85k for ULX3S (12k not supported)
FPGA_PKG = CABGA381  # CABGA381 for ULX3S

# configuration
SHELL = /bin/sh
FPGA_SPEED = 8    # FPGA speed grade (6,7,8) - all parts seem fine with fastest
LPF = ulx3s.lpf   # constraints
TARGET_FREQ = 25  # target frequency (MHz)

# included Verilog modules
PATH_LIB = ../../hardware
ADD_SRC += ${PATH_LIB}/book/ch01/ch01_pattern.v
ADD_SRC += ${PATH_LIB}/book/ch01/ch01_square.v
ADD_SRC += ${PATH_LIB}/book/ch02/ch02.v
ADD_SRC += ${PATH_LIB}/gfx/canv_disp_agu.v
ADD_SRC += ${PATH_LIB}/gfx/display.v
ADD_SRC += ${PATH_LIB}/gfx/tmds_encoder.v
ADD_SRC += ${PATH_LIB}/mem/clut.v
ADD_SRC += ${PATH_LIB}/mem/vram.v
# ecp5 arch modules
ADD_SRC += ${PATH_LIB}/arch/ecp5/clock2_gen.v
ADD_SRC += ${PATH_LIB}/arch/ecp5/dvi_generator.v

ch01: ch01.bit ch01.svf
ch02: ch02.bit ch02.svf

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

all: ch01 ch02

clean:
	rm -f *.json *.config *.bit .*.d *.svf *yosys.log

.PHONY: all clean
