# Isle Hardware

Isle hardware is designed in straightforward Verilog. You can find reference documentation and tests in each directory.

## Hardware Modules

* [arch](arch) - architecture specific modules (see below)
* [book](book) - designs to accompany _Building Isle_ book chapters
* [cpu](cpu) - RISC-V processor (forthcoming)
* [graphics](gfx) - display, drawing, text mode
* [memory](mem) - VRAM, CLUT, system memory
* [sys](sys) - CDC (and future system hardware)

### Architecture Specific

Architecture-specific FPGA designs, such as PLLs and I/O, are kept separate under `arch`. Isle currently includes support for two architectures; read [Isle Dev Boards](https://projectf.io/isle/dev-boards.html) for more details.

* Lattice [ECP5](arch/ecp5)
* Xilinx [XC7](arch/xc7)
