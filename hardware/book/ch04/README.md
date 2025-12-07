# Isle Chapter 4 - Text Mode

These Verilog designs accompany [Text Mode](http://projectf.io/isle/text-mode.html), chapter 4 of the _Building Isle_ book from the Project F blog.

See [boards](../../../boards/) for build and programming instructions.

## Verilog Modules

The chapter 4 design uses the following Verilog modules:

* `book/ch04/ch04.v`
* `gfx/display.v`
* `gfx/font_glyph.v`
* `gfx/textmode.v`
* `gfx/tmds_encoder.v` (not used in Verilator sim)
* `mem/clut.v`
* `mem/rom_sync.v`
* `mem/tram.v`

Each [board](../../../boards/) has its own top module plus relevant Architecture-specific modules under `arch/ecp5` and `arch/xc7`; check board make/build files for details.
