# Isle.Computer - Nexys Video Build Script (Chapter 1)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# build settings
set design_name "ch01"
set arch "xc7-dvi"
set board_name "nexys_video"
set fpga_part "xc7a200tsbg484-1"

# set reference directories for source files
set lib_dir [file normalize "./../../../hardware/"]
set proj_dir [file normalize "./../../../proj/"]

# read design sources
read_verilog "top_${design_name}.v"
read_verilog "${lib_dir}/book/ch01/ch01_pattern.v"
read_verilog "${lib_dir}/book/ch01/ch01_square.v"
read_verilog "${lib_dir}/gfx/display.v"
read_verilog "${lib_dir}/gfx/tmds_encoder.v"
# xc7 arch modules
read_verilog "${lib_dir}/arch/xc7/clock2_gen.v"
read_verilog "${lib_dir}/arch/xc7/dvi_generator.v"
read_verilog "${lib_dir}/arch/xc7/oserdes_10b.v"
read_verilog "${lib_dir}/arch/xc7/tmds_out.v"
# Starfield modules
read_verilog "${lib_dir}/math/lfsr.v"
read_verilog "${proj_dir}/starfield/starfield.v"

# read constraints
read_xdc "${design_name}.xdc"

# synth
synth_design -top "top_${design_name}" -part ${fpga_part}

# place and route
opt_design
place_design
route_design

# write bitstream
write_bitstream -force "${design_name}.bit"
