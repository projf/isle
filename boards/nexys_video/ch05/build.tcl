# Isle.Computer - Nexys Video Build Script (Chapter 5)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# Build Settings
set design_name "ch05"
set arch "xc7-dvi"
set board_name "nexys_video"
set fpga_part "xc7a200tsbg484-1"

set lib_dir [file normalize "./../../../hardware/"]
set proj_dir [file normalize "./../../../projects/"]

# Top module
read_verilog "top_${design_name}.v"

# Common Verilog
read_verilog "${lib_dir}/book/ch05/ch05.v"
read_verilog "${lib_dir}/book/ch05/FemtoRV32.v"
read_verilog "${lib_dir}/gfx/display.v"
read_verilog "${lib_dir}/gfx/font_glyph.v"
read_verilog "${lib_dir}/gfx/textmode.v"
read_verilog "${lib_dir}/gfx/tmds_encoder.v"
read_verilog "${lib_dir}/mem/clut.v"
read_verilog "${lib_dir}/mem/rom_sync.v"
read_verilog "${lib_dir}/mem/sysram.v"
read_verilog "${lib_dir}/mem/tram.v"
read_verilog "${lib_dir}/sys/xd.v"

# XC7 Arch
read_verilog "${lib_dir}/arch/xc7/clock_gen.v"
read_verilog "${lib_dir}/arch/xc7/clock2_gen.v"
read_verilog "${lib_dir}/arch/xc7/dvi_generator.v"
read_verilog "${lib_dir}/arch/xc7/oserdes_10b.v"
read_verilog "${lib_dir}/arch/xc7/tmds_out.v"

# Constraints
read_xdc "${design_name}.xdc"


# Build
synth_design -top "top_${design_name}" -part ${fpga_part}
opt_design
place_design
route_design
write_bitstream -force "${design_name}.bit"
