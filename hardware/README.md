# Isle Hardware

Written in Verilog. You can find reference documentation and tests in each directory.

The [requirements.txt](requirements.txt) in this directory is for [cocotb hardware tests](../docs/verilog-tests.md).

## Hardware Modules

* cpu - RISC-V processor (forthcoming)
* [graphics](gfx) - display, drawing, text mode
* memory - vram, system memory (forthcoming)

## Architecture Specific

* Lattice [ECP5](arch/ecp5)
* Xilinx [XC7](arch/xc7)

## Book Chapters

Designs for the Isle book on the Project F blog:

* Chapter 1 - [Display](book/ch01)
* Chapter 2 - Bitmap Graphics (forthcoming)
