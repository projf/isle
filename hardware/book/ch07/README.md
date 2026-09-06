# Isle Chapter 7 - Graphics Devices

These Verilog designs accompany [Graphics Devices](http://projectf.io/isle/graphics-devices.html), chapter 7 of _Building Isle_. See also: [Chapter 7 Software](../../../software/book/ch07/).

See [boards](../../../boards/) for build and programming instructions. See [Serial to Isle](../../../docs/serial-to-isle.md) for advice on connecting to Isle UART via USB.

## Verilog Modules

The chapter 7 design uses the following Verilog modules:

* `book/ch07/ch07.v`
* `cpu/FemtoRV32.v`
* `devs/dev_display.v`
* `devs/dev_earthrise.v`
* `devs/dev_sys.v`
* `devs/dev_uart.v`
* `gfx/canv_disp_agu.v`
* `gfx/canv_draw_agu.v`
* `gfx/circle.v`
* `gfx/display_sync_gen.v`
* `gfx/earthrise.v`
* `gfx/fline.v`
* `gfx/font_glyph.v`
* `gfx/line.v`
* `gfx/textmode.v`
* `gfx/tmds_encoder.v` (not used by Verilator sim)
* `io/uart_rx.v`
* `math/lfsr.v`
* `mem/clut.v`
* `mem/erlist.v`
* `mem/fifo_sync.v`
* `mem/rom_sync.v`
* `mem/sysram.v`
* `mem/tram.v`
* `mem/vram.v`
* `sys/xd.v`

Each [board](../../../boards/) has its own top module plus relevant architecture-specific modules under `arch/ecp5` and `arch/xc7`; check board make/build files for details.
