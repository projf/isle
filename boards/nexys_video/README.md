# Nexys Video Board Support

Isle supports the Digilent Nexys Video dev board with Xilinx XC7 FPGA. Isle also supports other [dev boards](../).

For the Nexys Video dev board, you need [Vivado](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools.html). Vivado can also program the Nexys Video, but I recommend using [openFPGALoader](https://github.com/trabucayre/openFPGALoader) as it's simpler and faster.

If you're new to Isle, the best place to start is [Isle FPGA Computer](http://projectf.io/isle/fpga-computer.html).

## Building

There is a Nexys Video top module for each chapter of the _Building Isle_ book, which you can read on the [Isle blog](https://projectf.io/isle/index.html).

Before you begin, locate your Vivado directory.

On Linux source the Vivado setting script to set the environment:

```shell
source /opt/Xilinx/2025.1/Vivado/settings64.sh  # adjust this path for your system
```

On Windows, run the settings batch file from the `Vivado` directory.

Then run **vivado** to build your chosen chapter. For example, to build the chapter 2 design:

```shell
cd isle/boards/nexys_video/ch02
vivado -mode batch -nojournal -source build_ch02.tcl
```

Each chapter top module uses an instance of the common chapter design from [hardware/book](../../hardware/book/).

### Board Programming

Program the Nexys Video with Vivado or openFPGALoader:

```shell
openFPGALoader -b nexysVideo ch02.bit
```

The Project F blog has a post covering [Vivado Tcl build scripts](http://projectf.io/posts/vivado-tcl-build-script/), including how to script board programming with Vivado.

## Clock Settings

The following table shows clock generation parameters for different display modes using the 100 MHz board clock of the Nexys Video.

| Parameter         | 640x480    | 1024x768   | 1366x768   | 1280x720   |
| ----------------- | ---------: | ---------: | ---------: | ---------: |
| Pixel Clock (MHz) | 25.2       | 65         | 72         | 74.25      |
| MULT_MASTER       | 31.5       | 32.5       | 54         | 37.125     |
| DIV_MASTER        | 5          | 5          | 5          | 5          |
| DIV_5X            | 5.0        | 2.0        | 3.0        | 2.0        |
| DIV_1X            | 25         | 10         | 15         | 10         |

`IN_PERIOD` should always be set to 10.0 (ns) to match the 100 MHz board clock.

NB. VCO (`CLK_IN × MULT_MASTER / DIV_MASTER`) range is 600 - 1200 MHz for Xilinx 7 series speed grade -1.
