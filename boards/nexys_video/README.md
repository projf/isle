# Nexys Video Board Support

For the Nexys Video dev board, you need [Vivado](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools.html). Vivado can also program the Nexys Video, but I recommend using [openFPGALoader](https://github.com/trabucayre/openFPGALoader) as it's simpler and faster.

Before you begin, locate your Vivado directory.

On Linux source the Vivado setting script to set the environment:

```shell
source /opt/Xilinx/2025.1/Vivado/settings64.sh  # adjust this path for your system
```

On Windows, run the settings batch file from the `Vivado` directory.

Then build a chapter design; for example:

```shell
cd isle/boards/nexys_video/ch01
vivado -mode batch -nojournal -source build_ch01.tcl
```

Program the Nexys Video with Vivado or openFPGALoader:

```shell
openFPGALoader -b nexysVideo ch01.bit
```

The Project F blog has a post covering [Vivado Tcl build scripts](http://projectf.io/posts/vivado-tcl-build-script/), including how to script board programming with Vivado.

Isle also supports other [dev boards](../).

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
