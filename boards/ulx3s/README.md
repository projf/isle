# ULX3S Board Support

For the ULX3S dev board, you need [Yosys](https://github.com/YosysHQ/yosys), [nextpnr](https://github.com/YosysHQ/nextpnr), and [openFPGALoader](https://github.com/trabucayre/openFPGALoader). All three are included in [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build).

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

Isle also supports other [dev boards](../).
