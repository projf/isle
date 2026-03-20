# Isle Hardware

Isle hardware is designed in straightforward Verilog.

* [docs](docs) - reference docs for hardware modules
* [tests](tests) - cocotb hardware tests

## Hardware Modules

* [arch](arch) - architecture specific modules (see below)
* [book](book) - designs to accompany _Building Isle_ book chapters
* [cpu](cpu) - RISC-V processor
* [devices](devs) - MMIO devices
* [graphics](gfx) - display, drawing, text mode
* [IO](io) - input/output (inc. uart)
* [math](math) - mathematics
* [memory](mem) - vram, fifo, system memory
* [sys](sys) - system hardware (inc. CDC)

### Architecture Specific

Architecture-specific FPGA designs, such as PLLs and I/O, are kept separate under `arch`. Isle currently includes support for two architectures; read [Isle Dev Boards](http://projectf.io/isle/dev-boards.html) for more details.

* Lattice [ECP5](arch/ecp5)
* Xilinx [XC7](arch/xc7)

![](../docs/img/guessing-on-ulx3s.jpeg?raw=true "")
