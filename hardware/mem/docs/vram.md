# VRAM

The **vram** (video ram) [[verilog src](../vram.v)] module holds bitmap graphics in block ram (bram). The default Isle vram design is 64 KiB as 16K x 32 bit. The vram is bit write, with a 32-bit write mask so you can set individual bits.

If vram shared main memory, we'd have to arbitrate between the display, drawing engine, and CPU, all while handling clock domain crossing and the latency of sdram. Having dedicated vram keeps things simple and predictable. We also support bit write, making 1, 2, and 4 bit graphics simpler and faster.

## Parameters

* `WORD` - machine word size (bits)
* `ADDRW` - vram address width (bits)
* `FILE_BMAP` - optional initial bitmap to load

For Isle, `WORD` must be set to **32** to match the architecture. `ADDRW` should be set to **14**, but may be set larger if you have enough block ram. Because bit write infers 32 x 2 KiB brams, you don't save any resources by setting `ADDRW` to less than 14.

The optional `FILE_BMAP` parameter allows a $readmemh format bitmap to be loaded at build time; this is mostly useful for testing. You can create a suitable $readmemh bitmap with [img2fmem](https://github.com/projf/fpgatools/tree/main/img2fmem).

## Signals

The vram is dual port, with a system and display port in different clock domains (discussed in more detail below).

### Input

* `clk_sys` - system clock
* `clk_pix` - pixel clock (frequency depends on [display](../../gfx/docs/display.md) mode)
* `wmask_sys` - 32-bit write mask (write-enable)
* `addr_sys` - system port word address
* `din_sys` - system data in
* `addr_disp` - display word address

### Output

* `dout_sys` - system data out
* `dout_disp` - display data out

## Bitmap Support

64 KiB vram supports:

* 672x384, 512x384, 640x400
  - 2 x 2-colour buffers
  - 1 x 4-colour buffer
* 336x192, 256x192, 320x200
  - 2 x 16-colour buffers
  - 1 x 256-colour buffer

Based on indexed colour with a palette handled by the [clut](clut.md) (colour lookup table).

64 KiB is the largest bit-write vram we can support in bram on the Lattice ECP5-25F and Xilinx A7-15T / S7-25.

## Ports

The system (sys) port is for reading and writing pixels. The system port is designed for interfacing with a drawing engine or CPU and is in the system clock domain. The display (disp) port is for reading pixel data for display output and is in the pixel clock domain.

The separate system and displays ports avoid contention between the graphics engine and display logic and form part of the clock-domain crossing (CDC) architecture that allows the system and display clocks to run independently.

### Latencies

* **system port** - 1 cycle read latency
* **display port** - 2 cycle read latency

The display port has a higher latency because of the output register to improve timing.

## Testing

There is a cocotb test bench [[python src](../test/vram.py)] that exercises this module. For advice on running hardware tests, see [Isle Verilog Tests](../../../docs/verilog-tests.md).

Most of the complexity depends on the dual-port bram implementation, which isn't visible with this inferred memory design.
