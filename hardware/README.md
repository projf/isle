# Isle Hardware

Isle hardware is designed in straightforward Verilog. You can find reference documentation and tests in each directory.

## Hardware Modules

* [cpu](cpu) - RISC-V processor (forthcoming)
* [graphics](gfx) - display, drawing, text mode
* [memory](mem) - VRAM, CLUT, system memory
* [sys](sys) - CDC (and future system hardware)

### Architecture Specific

Architecture-specific FPGA designs, such as PLLs and I/O, are kept separate.

* Lattice [ECP5](arch/ecp5)
* Xilinx [XC7](arch/xc7)

## Book Designs

Designs to accompany the Isle blog posts.

* [Chapter 1 - Display](https://projectf.io/isle/display.html) - [Designs](book/ch01)
* [Chapter 2 - Bitmap Graphics](https://projectf.io/isle/bitmap-graphics.html) - [Designs](book/ch02)
* [Chapter 3 - 2D Drawing](http://projectf.io/isle/2d-drawing.html) - [Designs](book/ch03)
* Chapter 4 - Text Mode (forthcoming)
* Chapter 5 - RISC-V CPU (forthcoming)
