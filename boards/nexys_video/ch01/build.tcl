# Isle.Computer - Nexys Video Build Script (Chapter 1)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# Build Settings
set design_name "ch01"
set arch "xc7-dvi"
set board_name "nexys_video"
set fpga_part "xc7a200tsbg484-1"

set lib_dir [file normalize "./../../../hardware/"]
set proj_dir [file normalize "./../../../projects/"]

# Top module
read_verilog "top_${design_name}.v"

# Common Verilog
read_verilog "${lib_dir}/book/ch01/ch01.v"
read_verilog "${lib_dir}/gfx/display.v"
read_verilog "${lib_dir}/gfx/tmds_encoder.v"

# XC7 Arch
read_verilog "${lib_dir}/arch/xc7/clock2_gen.v"
read_verilog "${lib_dir}/arch/xc7/dvi_generator.v"
read_verilog "${lib_dir}/arch/xc7/oserdes_10b.v"
read_verilog "${lib_dir}/arch/xc7/tmds_out.v"

# Project: Hitomezashi
read_verilog "${proj_dir}/hitomezashi/hitomezashi.v"

# Project: Starfield
read_verilog "${proj_dir}/starfield/starfield.v"
read_verilog "${lib_dir}/math/lfsr.v"

# Constraints
read_xdc "${design_name}.xdc"


# Build
synth_design -top "top_${design_name}" -part ${fpga_part}
opt_design
place_design
route_design
write_bitstream -force "${design_name}.bit"
