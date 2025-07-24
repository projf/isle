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
