# Isle Chapter 1 - Display

These Verilog designs accompany [Display](http://projectf.io/isle/display.html), chapter 1 of the building Isle book from the Project F blog.

See [boards](../../../boards/) for build and programming instructions.

## Verilog Modules

The chapter 1 design uses the following Verilog modules:

* `book/ch01/ch01_pattern.v`
* `book/ch01/ch01_square.v`
* `gfx/display.v`
* `gfx/tmds_encoder.v` (not used in Verilator sim)

Each [board](../../../boards/) has its own top module plus relevant Architecture-specific modules under `arch/ecp5` and `arch/xc7`; check board make/build files for details.
