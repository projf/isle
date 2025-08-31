# Lakritz Board Support

For the Lakritz dev board, you need [Yosys](https://github.com/YosysHQ/yosys), [nextpnr](https://github.com/YosysHQ/nextpnr), and [dfu-util](https://dfu-util.sourceforge.net). All three are included in [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build).

Then build and program. For example, for the chapter 1 design:

```shell
cd isle/boards/lakritz
make ch01

# power on Lakritz and run the following within 5 seconds
dfu-util -a 0 -D ch01.bit

# detach the DFU device and continue the boot process
dfu-util -a 0 -e
```

If you get a timing failure, rerun make. The Makefile uses `--randomize-seed` with nextpnr and sometimes you'll be unlucky with placement.

See the official [Lakritz README](https://github.com/machdyne/lakritz?tab=readme-ov-file#programming-lakritz) for more programming info.

Isle also supports other [dev boards](../).

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
