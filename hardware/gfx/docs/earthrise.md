# Earthrise 2D Drawing Engine

The **Earthrise** module [[verilog src](../earthrise.v)] is a simple processor that decodes and executes graphics instructions for pixels, lines, triangles, rects, and circles.

This document provides a summary of the hardware module. See [Earthrise Programming](../../../docs/earthrise-programming.md) for drawing pixels, lines, and shapes. 

See the [2D Drawing](http://projectf.io/isle/2d-drawing.html) blog post for more information on the use of this module.

_to do_

## Parameters

* `CORDW` - signed coordinate width (bits)
* `WORD` - machine word size (bits)
* `CANV_SHIFTW` - vram address shift width (bits)
* `COLRW` - colour/pattern width (bits)
* `ER_ADDRW` - command list address width
* `VRAM_ADDRW` - vram address width (bits)

For Isle, `CORDW` must be set to **16** and `WORD` must be set to **32**.

## Signals
