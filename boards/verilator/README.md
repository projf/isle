# Verilator/SDL Support

By combining [Verilator](https://www.veripool.org/verilator/) and [SDL](https://www.libsdl.org), you can run Isle on another computer. Read [Verilog Simulation with Verilator and SDL](http://projectf.io/posts/verilog-sim-verilator-sdl/) for more details. Isle also supports physical FPGA [dev boards](../).

Be aware that Isle typically runs several times slower in simulation than on an FPGA dev board. For Isle designs with a CPU, I see ~18 FPS on an Apple M1. Your mileage may vary.

On macOS, colour rendering is incorrect on high-gamut displays due to the way LibSDL v2 handles colour spaces. The only fix I've found is to temporarily set your monitor to sRGB colour profile. I plan to move to LibSDL v3 at some point, but it's not a high priority right now.

## Designs

The following designs are available to accompany the [Isle blog posts](https://projectf.io/isle/fpga-computer.html).

* [ch01](../../hardware/book/ch01) - Display
* [ch02](../../hardware/book/ch02) - Bitmap Graphics
* [ch03](../../hardware/book/ch03) - 2D Drawing
* ch04 - Text Mode (forthcoming)
* ch05 - RISC-V CPU (forthcoming)

There is a Verilator top module for each chapter in this directory, which uses an instance of the common chapter design from [hardware/book](../../hardware/book/). There is also a top-level C++ main file for each chapter.

Many chapters have parameters you can edit in the matching top module. For example, in `top_ch02.v` you can choose the bitmap and palette to load.

## Install Dependencies

* C++ Toolchain
* Verilator 5.006+
* SDL v2

See [Verilog Simulation with Verilator and SDL](http://projectf.io/posts/verilog-sim-verilator-sdl/#installing-dependencies) for installation instructions.

## Building

Once you have dependencies installed, run make for the chapter you want:

```shell
cd isle/boards/verilator
make ch01
./obj_dir/ch01
```

To enable full screen display, set `FULLSCREEN` to true in the main C++ file for that chapter, e.g. `boards/verilator/main_ch01.cpp`.

### Unknown Verilator Lint Message Code

Verilator introduces new lint waivers from time to time; unfortunately, this trips up older versions of Verilator. If Verilator gives an error message of the form "Unknown Verilator lint message code" you have two options:

1. Upgrade to a newer version of Verilator
2. Remove the lint waivers from the corresponding Verilog files

## 672x384 Display Timings

Verilator designs use their own 672x384 display timings with 25 MHz clock. The pixel and system clock are both 25 MHz in Verilator simulation. Chapter 1 uses 640x480 display in line with other dev boards.

We want to as near 60 Hz and 25 MHz as possible, so we use modified 640x480 timings with 800x521 total pixels for 59.98 Hz.

```
Horizontal Timings
Active Pixels        672
Front Porch           16
Sync Width            64
Back Porch            48
Blanking Total       128
Total Pixels         800
Sync Polarity        pos

Vertical Timings
Active Lines         384
Front Porch           10
Sync Width             2
Back Porch           125
Blanking Total       137
Total Lines          521
Sync Polarity        pos
```
