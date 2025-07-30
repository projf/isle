# Verilator/SDL Support

By combining [Verilator](https://www.veripool.org/verilator/) and [SDL](https://www.libsdl.org), you can run Isle on your computer. Read [Verilog Simulation with Verilator and SDL](http://projectf.io/posts/verilog-sim-verilator-sdl/) for more details.

Be aware that Isle typically runs several times slower in simulation than on an [FPGA dev board](../). For Isle designs with a CPU, I see ~18 FPS on an Apple M1. Your mileage may vary.

## Installing Dependencies

You need:

* C++ Toolchain
* Verilator 5.006+
* SDL v2

See [Verilog Simulation with Verilator and SDL](http://projectf.io/posts/verilog-sim-verilator-sdl/#installing-dependencies) for installation instructions.

## Building Designs for Verilator

Once you have dependencies installed, run make for the chapter you want:

```shell
cd isle/boards/verilator
make ch01
./obj_dir/ch01
```

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
