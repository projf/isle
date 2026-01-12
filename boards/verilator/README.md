# Verilator/SDL Support

By combining [Verilator](https://www.veripool.org/verilator/) and [SDL](https://www.libsdl.org), you can run Isle on another computer (Linux, Mac, or Windows). Isle also supports physical FPGA [dev boards](../).

Be aware that Isle typically runs several times slower in simulation than on an FPGA dev board. For Isle designs with a CPU, I see ~18 FPS on an Apple M1. Your mileage may vary.

On macOS, colour rendering is incorrect on high-gamut displays due to the way LibSDL v2 handles colour spaces. The only fix I've found is to temporarily set your monitor to sRGB colour profile. I plan to move to LibSDL v3 at some point, but it's not a high priority right now.

If you're new to Isle, the best place to start is [Isle FPGA Computer](http://projectf.io/isle/fpga-computer.html).

## Building

There is a Verilator top module for each chapter of the _Building Isle_ book, which you can read on the [Isle blog](https://projectf.io/isle/index.html).

[Install dependencies](#install-dependencies) if you haven't already.

Use **make** to build your chosen chapter. For example, to build the chapter 4 design:

```shell
cd isle/boards/verilator/ch04
make
./obj_dir/ch04
```

To enable full screen display, set `FULLSCREEN` to true in the main C++ file for that chapter, e.g. `boards/verilator/main_ch04.cpp`.

Many chapters have parameters you can edit in the matching top module. For example, in `top_ch02.v` you can choose the bitmap and palette to load.

Each chapter top module uses an instance of the common chapter design from [hardware/book](../../hardware/book/). There is also a top-level C++ main file for each design.

### Unknown Verilator Lint Message Code

Verilator introduces new lint waivers from time to time; unfortunately, this trips up older versions of Verilator. If Verilator gives an error message of the form "Unknown Verilator lint message code" you have two options:

1. Upgrade to a newer version of Verilator
2. Remove the lint waivers from the corresponding Verilog files

## Install Dependencies

* C++ Toolchain
* Verilator 5.006+
* SDL v2

### Linux

For Debian, Ubuntu, and Pop!_OS:

```shell
apt install build-essential verilator libsdl2-dev
```

On Arch:

```shell
pacman -S base-devel verilator sdl2
```

Other Linux distros and BSD will be similar.

### macOS

Install the [Homebrew](https://brew.sh/) package manager; this will also install Xcode Command Line Tools.

Once Homebrew is installed, you can run:

```shell
brew install verilator sdl2
```

### Windows

Windows users can run Verilator with SDL under Windows Subsystem for Linux. [WSL2 supports GUI Linux apps](https://learn.microsoft.com/en-us/windows/wsl/tutorials/gui-apps) in Windows 10 Build 19044+ and Windows 11.

Once you have WSL2 running, you can use the Linux instructions (above). I have successfully tested Verilator/SDL simulations with Debian 12 running on Windows 10.

## 672x384 Display Timings

Verilator designs use their own 672x384 display timings with 20 MHz clock. The pixel and system clock are both 20 MHz in Verilator simulation.

We want to as near 60 Hz and 20 MHz as possible, 825x404 at 20 MHz is 60.006 MHz.

```
Horizontal Timings
Active Pixels        672
Front Porch           23
Sync Width            20
Back Porch           110
Blanking Total       153
Total Pixels         825
Sync Polarity        pos

Vertical Timings
Active Lines         384
Front Porch            5
Sync Width             5
Back Porch            10
Blanking Total        20
Total Lines          404
Sync Polarity        pos
```
