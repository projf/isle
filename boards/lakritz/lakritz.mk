# Isle.Computer - Lakritz Makefile Include
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# FPGA IC
FPGA_TYPE = 25k  # 25k for Lakrizt
FPGA_PKG = CABGA256  # CABGA256 for Lakritz

# configuration
SHELL = /bin/sh
FPGA_SPEED = 8     # FPGA speed grade (6,7,8) - all parts seem fine with fastest
LPF = lakritz.lpf  # constraints
TARGET_FREQ = 25   # target frequency (MHz)

# synthesis (secondary expansion because ADD_SRC is set after rule)
.SECONDEXPANSION:
%.json: top_%.v $$(ADD_SRC)
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
