# Lakritz Board Support

Isle supports the Machdyne Lakritz dev board with ECP5 FPGA. Isle also supports other [dev boards](../).

For the Lakritz dev board, you need [Yosys](https://github.com/YosysHQ/yosys), [nextpnr](https://github.com/YosysHQ/nextpnr), and [dfu-util](https://dfu-util.sourceforge.net). All three are included in [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build).

## Building

There is a Lakritz top module for each chapter of the _Building Isle_ book. The top module uses an instance of the common chapter design from [hardware/book](../../hardware/book/).

Use **make** to build your chosen chapter. For example, to build the chapter 2 design:

```shell
cd isle/boards/lakritz
make ch02
```

If you get a timing failure, rerun make. The Makefile uses `--randomize-seed` with nextpnr and sometimes you'll be unlucky with placement.

Many chapters have parameters you can edit in the matching top module. For example, in `top_ch02.v` you can choose the bitmap and palette to load.

### Board Programming

```shell
# power on Lakritz and run the following within 5 seconds
dfu-util -a 0 -D ch02.bit

# detach the DFU device and continue the boot process
dfu-util -a 0 -e
```

See the official [Lakritz README](https://github.com/machdyne/lakritz?tab=readme-ov-file#programming-lakritz) for more programming info.

## Clock Settings

The following table shows clock generation parameters for different display modes using the 48 MHz board clock of the Lakritz. To understand how these values are calculated, see [ECP5 FPGA Clock Generation](https://projectf.io/posts/ecp5-fpga-clock/).

| Parameter         | 640x480    | 1024x768*  | 1366x768   | 1280x720*  |
| ----------------- | ---------: | ---------: | ---------: | ---------: |
| Pixel Clock (MHz) | 25.2       | 64.8       | 72         | 74.4       |
| CLKI_DIV          | 8          | 4          | 2          | 4          |
| CLKFB_DIV         | 21         | 27         | 15         | 31         |
| CLKOP_DIV         | 4          | 2          | 2          | 2          |
| CLKOP_CPHASE      | 2          | 1          | 1          | 1          |
| CLKOS_DIV         | 20         | 10         | 10         | 10         |
| CLKOS_CPHASE      | 10         | 5          | 5          | 5          |

_\*1024x768 should be 65 MHz and 1280x720 should be 74.25 MHz, but these clock frequencies are still withing spec ±0.5%._
