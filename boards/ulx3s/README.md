# ULX3S Board Support

Isle supports the Radiona ULX3S dev board with ECP5 FPGA. Isle also supports other [dev boards](../).

For the ULX3S dev board, you need [Yosys](https://github.com/YosysHQ/yosys), [nextpnr](https://github.com/YosysHQ/nextpnr), and [openFPGALoader](https://github.com/trabucayre/openFPGALoader). All three are included in [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build).

## Building

There is a ULX3S top module for each chapter of the _Building Isle_ book. The top module uses an instance of the common chapter design from [hardware/book](../../hardware/book/).

Before building, update `isle/boards/ulx3s/Makefile` to match your FPGA part:

```
FPGA_TYPE = 85k  # 25K, 45k, or 85k for ULX3S (12k not supported)
```

Then run **make** to build your chosen chapter. For example, to build the chapter 2 design:

```shell
cd isle/boards/ulx3s
make ch02
```

If you get a timing failure, rerun make. The Makefile uses `--randomize-seed` with nextpnr and sometimes you'll be unlucky with placement.

Many chapters have parameters you can edit in the matching top module. For example, in `top_ch02.v` you can choose the bitmap and palette to load.

### Board Programming

```shell
openFPGALoader --board ulx3s ch02.bit
```

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
