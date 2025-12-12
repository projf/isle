# ULX3S Board Support

Isle supports the Radiona ULX3S dev board with ECP5 FPGA. Isle also supports other [dev boards](../).

For the ULX3S dev board, you need [Yosys](https://github.com/YosysHQ/yosys), [nextpnr](https://github.com/YosysHQ/nextpnr), and [openFPGALoader](https://github.com/trabucayre/openFPGALoader). All three are included in [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build).

If you're new to Isle, the best place to start is [Isle FPGA Computer](http://projectf.io/isle/fpga-computer.html).

## Building

There is a ULX3S top module for each chapter of the _Building Isle_ book, which you can read on the [Isle blog](https://projectf.io/isle/index.html).

Before building, update `FPGA_TYPE` in `isle/boards/ulx3s/ulx3s.mk` to match your FPGA:

```
FPGA_TYPE = 85k  # 25K, 45k, or 85k for ULX3S (12k not supported)
```

Then run **make** to build your chosen chapter. For example, to build the chapter 4 design:

```shell
cd isle/boards/ulx3s/ch04
make
```

If you get a timing failure, run `make clean && make`. The Makefile uses `--randomize-seed` with nextpnr and sometimes you'll be unlucky with placement.

Many chapters have parameters you can edit in the matching top module. For example, in `top_ch02.v` you can choose the bitmap and palette to load.

Each chapter top module uses an instance of the common chapter design from [hardware/book](../../hardware/book/).

### Board Programming

Program the ULX3S with openFPGALoader. For example, for chapter 4:

```shell
openFPGALoader --board ulx3s ch04.bit
```

The build process also creates an SVF (Serial Vector Format) file if your preferred board programming method requires that.

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
