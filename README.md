# 🏝️ Isle FPGA Computer

Welcome to Isle. Isle is a simple, modern computer — an open design that encourages tinkering, experimentation, and doing your own thing. It's early days for the Isle project. The current designs are focused on hardware; CPU and software will follow before too long.

Learn more and get started with the Project F blog: [Isle FPGA Computer](http://projectf.io/isle/fpga-computer.html)

Follow [@WillFlux@mastodon.social](https://mastodon.social/@WillFlux) for updates.

## Building Isle Book

As I build each new component, I introduce it in its own chapter with a dedicated Verilog design.

* Chapter 1 - **Display**: [Design](hardware/book/ch01) - [Blog](https://projectf.io/isle/display.html)
* Chapter 2 - **Bitmap Graphics**: [Design](hardware/book/ch02) - [Blog](https://projectf.io/isle/bitmap-graphics.html)
* Chapter 3 - **2D Drawing**: [Design](hardware/book/ch03) - [Blog](http://projectf.io/isle/2d-drawing.html)
* Chapter 4 - **Text Mode**: [Design](hardware/book/ch04) - [Blog](http://projectf.io/isle/text-mode.html)
* Chapter 5 - **RISC-V CPU** (forthcoming)

For build instructions see [dev boards](boards). Isle supports Lattice ECP5, Xilinx XC7, and Verilator/SDL simulation on Linux/Mac/Windows.

## Repo Layout

* [boards](boards) - supported dev boards and simulators
* [docs](docs) - high-level docs and project notes
* [hardware](hardware) - Verilog hardware
* [projects](projects) - projects that run on Isle
* [res](res) - resource files (bitmaps, drawings, palettes)
* [software](software) - programs to run on Isle (forthcoming)
* [tools](tools) - tools to build Isle software and resources

The [requirements.txt](requirements.txt) is for [Python tools](tools) and [cocotb hardware tests](docs/verilog-tests.md).

## Thank You!

Special thanks to my **sponsors** who've stuck with me as I develop Isle: [Alexandre Mutel](https://github.com/xoofx), [Daniel Cliche](https://github.com/danodus), [David C. Norris](https://github.com/dcnorris), [dvir](https://github.com/dvirdc), [Justin Finkelstein](https://github.com/iamfinky), [kromych](https://github.com/kromych), [Martin Young](https://github.com/InternalCakeEngine), [Matt Venn](https://github.com/mattvenn), [Paul Sajna](https://github.com/sajattack), [Renaldas Zioma](https://github.com/rejunity), and those who wish to remain anonymous.

![](docs/img/ulx3s-1024x768-lvds.jpeg?raw=true "")
