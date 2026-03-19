# Isle Chapter 6 - Input Output

These Verilog designs accompany _Input Output_, chapter 6 of _Building Isle_. See also: [Chapter 6 Software](../../../software/book/ch06/).

See [boards](../../../boards/) for build and programming instructions. See [Serial to Isle](../../../docs/serial-to-isle.md) for advice on connecting to Isle UART via USB.

## Verilog Modules

The chapter 6 design uses the following Verilog modules:

* `book/ch06/ch06.v`
* `cpu/FemtoRV32.v`
* `devs/gfx_dev.v`
* `devs/sys_dev.v`
* `devs/uart_dev.v`
* `gfx/display.v`
* `gfx/font_glyph.v`
* `gfx/textmode.v`
* `gfx/tmds_encoder.v` (not used by Verilator sim)
* `io/uart_rx.v`
* `math/lfsr.v`
* `mem/clut.v`
* `mem/fifo_sync.v`
* `mem/rom_sync.v`
* `mem/sysram.v`
* `mem/tram.v`
* `sys/xd.v`

Each [board](../../../boards/) has its own top module plus relevant architecture-specific modules under `arch/ecp5` and `arch/xc7`; check board make/build files for details.
