# ULX3S Board Support

For the ULX3S dev board, you need [Yosys](https://github.com/YosysHQ/yosys), [nextpnr](https://github.com/YosysHQ/nextpnr), and [openFPGALoader](https://github.com/trabucayre/openFPGALoader). All three are included in [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build). Isle also supports other [dev boards](../).

## Designs

The following designs are available to accompany the [Isle blog posts](https://projectf.io/isle/fpga-computer.html).

* [ch01](../../hardware/book/ch01) - Display
* [ch02](../../hardware/book/ch02) - Bitmap Graphics
* [ch03](../../hardware/book/ch03) - 2D Drawing
* ch04 - Text Mode (forthcoming)
* ch05 - RISC-V CPU (forthcoming)

There is a ULX3S top module for each chapter in this directory, which uses an instance of the common chapter design from [hardware/book](../../hardware/book/).

Many chapters have parameters you can edit in the matching top module. For example, in `top_ch02.v` you can choose the bitmap and palette to load.

## Building

Update `isle/boards/ulx3s/Makefile` to match your FPGA part:

```
FPGA_TYPE = 85k  # 25K, 45k, or 85k for ULX3S (12k not supported)
```

Then build and program. For example, for the chapter 1 design:

```shell
cd isle/boards/ulx3s
make ch01
openFPGALoader --board ulx3s ch01.bit
```

If you get a timing failure, rerun make. The Makefile uses `--randomize-seed` with nextpnr and sometimes you'll be unlucky with placement.

## Clock Settings

The following table shows clock generation parameters for different display modes using the 25 MHz board clock of the ULX3S. To understand how these values are calculated, see [ECP5 FPGA Clock Generation](https://projectf.io/posts/ecp5-fpga-clock/).

| Parameter         | 640x480    | 1024x768   | 1366x768   | 1280x720*  |
| ----------------- | ---------: | ---------: | ---------: | ---------: |
| Pixel Clock (MHz) | 25.2       | 65         | 72         | 74         |
| CLKI_DIV          | 25         | 1          | 5          | 5          |
| CLKFB_DIV         | 126        | 13         | 72         | 74         |
| CLKOP_DIV         | 4          | 2          | 2          | 2          |
| CLKOP_CPHASE      | 2          | 1          | 1          | 1          |
| CLKOS_DIV         | 20         | 10         | 10         | 10         |
| CLKOS_CPHASE      | 10         | 5          | 5          | 5          |

_\*1280x720 should be 74.25 MHz, but this clock frequency is still withing spec ±0.5%._
