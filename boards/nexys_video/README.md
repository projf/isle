# Nexys Video Board Support

Isle supports the Digilent Nexys Video dev board with Xilinx XC7 FPGA. Isle also supports other [dev boards](../).

For the Nexys Video dev board, you need [Vivado](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools.html) to build Isle. Vivado can also program the Nexys Video, but I recommend using [openFPGALoader](https://github.com/trabucayre/openFPGALoader) as it's simpler and faster.

If you're new to Isle, the best place to start is [Isle FPGA Computer](http://projectf.io/isle/fpga-computer.html).

_I plan to look at open-source XC7 tools in future._

## Building

There is a Nexys Video top module for each chapter of the _Building Isle_ book, available on the [Isle blog](http://projectf.io/isle/index.html).

Before you begin, locate your Vivado directory.

On **Linux**, source the Vivado setting script to set the environment:

```shell
source /opt/Xilinx/2025.1/Vivado/settings64.sh  # adjust this path for your system
```

On **Windows**, run the `settings64.bat` batch file from the `Vivado` directory.

Then run **Vivado** to build your chosen chapter. For example, to build the chapter 4 design:

```shell
cd isle/boards/nexys_video/ch04
vivado -mode batch -nojournal -source build.tcl
```

Each chapter's top module uses an instance of the common chapter design from [hardware/book](../../hardware/book/).

### Board Programming

Program the Nexys Video with Vivado or openFPGALoader. For example, for chapter 4:

```shell
openFPGALoader -b nexysVideo ch04.bit
```

The Project F blog has a post covering [Vivado Tcl build scripts](http://projectf.io/posts/vivado-tcl-build-script/), including how to script board programming with Vivado.

### UART

See [Serial to Isle](../../docs/serial-to-isle.md) for advice on connecting to Isle UART via USB.

## Clock Settings

The following table shows clock generation parameters for different [display modes](../../hardware/include/display_modes.vh) using the 100 MHz board clock of the Nexys Video.

| Parameter         | 640x480    | 1024x768   | 1366x768   | 1280x720   | 1920x1080* |
| ----------------- | ---------: | ---------: | ---------: | ---------: | ---------: |
| Isle DISPLAY_MODE | 0          | 1          | 2          | 4          | 5          |
| Pixel Clock (MHz) | 25.2       | 65         | 72         | 74.25      | 148.5      |
| MULT_MASTER       | 31.5       | 32.5       | 54         | 37.125     | 37.125     |
| DIV_MASTER        | 5          | 5          | 5          | 5          | 5          |
| DIV_5X            | 5.0        | 2.0        | 3.0        | 2.0        | 1.0        |
| DIV_1X            | 25         | 10         | 15         | 10         | 5          |

_\*1920x1080 does not meet timing on Nexys Video, see discussion, below._

`IN_PERIOD` should always be set to 10.0 (ns) to match the 100 MHz board clock.

NB. VCO (`CLK_IN × MULT_MASTER / DIV_MASTER`) range is 600 - 1200 MHz for Xilinx 7 series speed grade -1.

### 1920x1080p60

I don't recommend using 1080p unless you have a specific requirement for it, such as video capture. Lower resolutions support all Isle features while meeting FPGA timing.

1920x1080p60 is out of spec for Xilinx 7 series FPGAs, but it generally works in practice on the Nexys Video. For 1920x1080p60 (pixel clock 148.5 MHz), the 5x TMDS pixel clock is 742.5 MHz.

We use `BUFIO`, the fastest clock buffer, in the [pixel clock generator](../../hardware/arch/xc7/clock2_gen.v), but its maximum frequency is 600 MHz on speed grade -1 or 680 MHz on faster speed grades ([DS181](https://docs.amd.com/v/u/en-US/ds181_Artix_7_Data_Sheet) table 33).

If we look at the Vivado timing report at 1080p, we can see this issue (1.667 ns is 600 MHz, 1.347 ns is 742.5 MHz):

```
Check Type  Corner  Lib Pin             Required(ns)  Actual(ns)  Slack(ns)  Location
Min Period  n/a     OSERDESE2/CLK       1.667         1.347       -0.320     OLOGIC_X1Y140
```

1920x1080p60 usually works in practice because the specs have to cover the worst-case for the process (variations in the physical FPGA IC), voltage, and temperature. For example, you're probably not running your Nexys Video FPGA at the maximum 85ºC. The Nexys Video board also includes a [TI TMDS141](https://www.ti.com/product/TMDS141) HDMI redriver, so the FPGA only has to drive the TMDS signal a short distance on the PCB.

TVs are generally pickier than computer monitors. If your TV doesn't like running Isle at 1080p, try 720p instead.
