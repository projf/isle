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
