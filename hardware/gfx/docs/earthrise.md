# Earthrise 2D Drawing Engine

The **Earthrise** module [[verilog src](../earthrise.v)] is a simple processor that decodes and executes graphics instructions for pixels, lines, triangles, rects, and circles.

This document provides a summary of the hardware module. See [Earthrise Programming](../../../docs/earthrise-programming.md) for drawing pixels, lines, and shapes. 

See the [2D Drawing](http://projectf.io/isle/2d-drawing.html) blog post for more information on the use of this module.

_I'll add more details on the internal operation of Earthrise in future updates._

## Parameters

* `CORDW` - signed coordinate width (bits)
* `WORD` - machine word size (bits)
* `CANV_SHIFTW` - vram address shift width (bits)
* `COLRW` - colour/pattern width (bits)
* `ER_ADDRW` - command list address width
* `VRAM_ADDRW` - vram address width (bits)

For Isle, `CORDW` must be set to **16** and `WORD` must be set to **32**.

## Signals

### Input

* `clk` - clock
* `rst` - reset
* `start` - start execution
* `canv_w`, `canv_h` - canvas width and height (in pixels)
* `canv_bpp` - canvas bits per pixel
* `cmd_list` - command list data
* `addr_base` - address of first pixel in canvas
* `addr_shift` - address shift bits

`addr_base` is the base address of the canvas buffer (first pixel) in vram.

The address shift, `addr_shift`, determines how the raw pixel address is split between vram address and pixel index.

Address shift is set based on the bits per pixel:

* 1 bit: `addr_shift = 5`
* 2 bit: `addr_shift = 4`
* 4 bit: `addr_shift = 3`
* 8 bit: `addr_shift = 2`

For example, 2 bits per pixel mean you have 16 pixels per 32-bit word, and 16 is 2^4.

### Output

* `pc` - Earthrise program counter (byte address)
* `vram_addr` - address in vram
* `vram_din` - vram data in
* `vram_wmask` - vram write mask
* `busy` - execution in progress
* `done` - commands complete (high for one tick)
* `instr_invalid` - invalid instruction
