# Isle Chapter 5 - RISC-V CPU

These Verilog designs accompany [RISC-V CPU](https://projectf.io/isle/riscv-cpu.html), chapter 5 of _Building Isle_. See also: [Chapter 5 Software](../../../software/book/ch05/).

See [boards](../../../boards/) for build and programming instructions.

## Verilog Modules

The chapter 5 design uses the following Verilog modules:

* `book/ch05/ch05.v`
* `cpu/FemtoRV32.v`
* `gfx/display.v`
* `gfx/font_glyph.v`
* `gfx/textmode.v`
* `gfx/tmds_encoder.v` (not used by Verilator sim)
* `mem/clut.v`
* `mem/rom_sync.v`
* `mem/sysram.v`
* `mem/tram.v`
* `sys/xd.v`

Each [board](../../../boards/) has its own top module plus relevant architecture-specific modules under `arch/ecp5` and `arch/xc7`; check board make/build files for details.
