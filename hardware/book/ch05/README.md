# Isle Chapter 5 - RISC-V CPU

These Verilog designs accompany [RISC-V CPU](https://projectf.io/isle/riscv-cpu.html), chapter 5 of _Building Isle_. See also: [Chapter 5 Software](../../../software/book/ch05/).

This chapter includes FemtoRV32 ([femtorv32_quark_bicycle](https://github.com/BrunoLevy/learn-fpga/tree/master/FemtoRV/RTL/PROCESSOR)) by Bruno Levy and Matthias Koch under [BSD-3-Clause license](FemtoRV32-LICENSE). This CPU design supports the RV32I ISA and is specific to this chapter. Later chapters will support other extensions, such as multiply (RV32M) and compressed instructions (RV32C).

See [boards](../../../boards/) for build and programming instructions.

## Verilog Modules

The chapter 5 design uses the following Verilog modules:

* `book/ch05/ch05.v`
* `book/ch05/FemtoRV32.v`
* `gfx/display.v`
* `gfx/font_glyph.v`
* `gfx/textmode.v`
* `gfx/tmds_encoder.v` (not used in Verilator sim)
* `mem/clut.v`
* `mem/rom_sync.v`
* `mem/sysram.v`
* `mem/tram.v`
* `sys/xd.v`

Each [board](../../../boards/) has its own top module plus relevant architecture-specific modules under `arch/ecp5` and `arch/xc7`; check board make/build files for details.
