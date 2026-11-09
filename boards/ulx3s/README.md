# ULX3S Board Support

Isle supports the Radiona ULX3S dev board with ECP5 FPGA. Isle also supports other [dev boards](../).

For the ULX3S dev board, you need [Yosys](https://github.com/YosysHQ/yosys), [nextpnr](https://github.com/YosysHQ/nextpnr), and [openFPGALoader](https://github.com/trabucayre/openFPGALoader). All three are included in [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build).

If you're new to Isle, the best place to start is [Isle FPGA Computer](http://projectf.io/isle/fpga-computer.html).

## Building

There is a ULX3S top module for each chapter of the _Building Isle_ book, available on the [Isle blog](http://projectf.io/isle/index.html).

Before building, update `FPGA_TYPE` in `isle/boards/ulx3s/ulx3s.mk` to match your FPGA:

```
FPGA_TYPE = 85k  # 25K, 45k, or 85k for ULX3S (12k not supported)
```

Then run **make** to build your chosen chapter. For example, to build the chapter 4 design:

```shell
cd isle/boards/ulx3s/ch04
make
```

If you get a timing failure, run `make clean && make`. The Makefile uses `--randomize-seed` with nextpnr, and sometimes you'll be unlucky with placement. You should also ensure you're running recent versions of Yosys and nextpnr.

Many chapters have parameters you can edit in the matching top module. For example, in `top_ch02.v` you can choose the bitmap and palette to load.

Each chapter's top module uses an instance of the common chapter design from [hardware/book](../../hardware/book/).

### Board Programming

Program the ULX3S with openFPGALoader. For example, for chapter 4:

```shell
openFPGALoader --board ulx3s ch04.bit
```

The build process also creates an SVF (Serial Vector Format) file if your preferred board programming method requires that.

### UART

See [Serial to Isle](../../docs/serial-to-isle.md) for advice on connecting to Isle UART via USB.

## Clock Settings

The following table shows clock generation parameters for the default 1280x720p60 [display mode](../../hardware/include/display_modes.vh) using the 25 MHz board clock of the ULX3S.

| Parameter         | 1280x720*  |
| ----------------- | ---------: |
| Isle DISPLAY_MODE | 1          |
| Pixel Clock (MHz) | 74         |
| CLKI_DIV          | 5          |
| CLKFB_DIV         | 74         |
| CLKOP_DIV         | 2          |
| CLKOP_CPHASE      | 1          |
| CLKOS_DIV         | 10         |
| CLKOS_CPHASE      | 5          |

_\*1280x720 should be 74.25 MHz, but this clock frequency is still within spec ±0.5%._
