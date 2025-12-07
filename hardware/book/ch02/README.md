# Isle Chapter 2 - Bitmap Graphics

These Verilog designs accompany [Bitmap Graphics](http://projectf.io/isle/bitmap-graphics.html), chapter 2 of the _Building Isle_ book from the Project F blog.

See [boards](../../../boards/) for build and programming instructions.

## Verilog Modules

The chapter 2 design uses the following Verilog modules:

* `book/ch02/ch02.v`
* `gfx/canv_disp_agu.v`
* `gfx/display.v`
* `gfx/tmds_encoder.v` (not used in Verilator sim)
* `mem/clut.v`
* `mem/vram.v`

Each [board](../../../boards/) has its own top module plus relevant Architecture-specific modules under `arch/ecp5` and `arch/xc7`; check board make/build files for details.
