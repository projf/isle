# Isle Chapter 3 - 2D Drawing

These Verilog designs accompany [2D Drawing](http://projectf.io/isle/2d-drawing.html), chapter 3 of the _Building Isle_ book from the Project F blog.

See [boards](../../../boards/) for build and programming instructions.

## Verilog Modules

The chapter 3 design uses the following Verilog modules:

* `book/ch03/ch03.v`
* `gfx/canv_disp_agu.v`
* `gfx/canv_draw_agu.v`
* `gfx/circle.v`
* `gfx/display.v`
* `gfx/earthrise.v`
* `gfx/fline.v`
* `gfx/line.v`
* `gfx/tmds_encoder.v` (not used in Verilator sim)
* `mem/clut.v`
* `mem/erlist.v`
* `mem/vram.v`

Each [board](../../../boards/) has its own top module plus relevant architecture-specific modules under `arch/ecp5` and `arch/xc7`; check board make/build files for details.
