# Isle Hardware

Isle hardware is designed in straightforward Verilog. You can find reference documentation and tests in each directory.

## Hardware Modules

* cpu - RISC-V processor (forthcoming)
* [graphics](gfx) - display, drawing, text mode
* memory - vram, system memory (forthcoming)

The [requirements.txt](requirements.txt) in this directory is for [cocotb hardware tests](../docs/verilog-tests.md).

### Architecture Specific

Architecture-specific FPGA designs, such as PLLs, are kept separate.

* Lattice [ECP5](arch/ecp5)
* Xilinx [XC7](arch/xc7)

## Book Designs

Designs to accompany the [Isle book](https://projectf.io/isle/index.html) on the Project F blog.

* Chapter 1 - Display: [Blog](https://projectf.io/isle/display.html) | [Designs](book/ch01)
* Chapter 2 - Bitmap Graphics (forthcoming)
