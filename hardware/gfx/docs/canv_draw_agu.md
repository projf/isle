# Canvas Draw Address Generation

The canvas draw address generation unit **canv_draw_agu** [[verilog src](../canv_draw_agu.v)] calculates the [vram](../../mem/docs/vram.md) address in a canvas buffer for drawing. Drawing addresses are based on coordinates and don't increase sequentially, so the approach used in the [display AGU](canv_disp_agu.md) is not appropriate here.

This module has 3 cycles of latency and supports pipelining. See [Earthrise](earthrise.md) for an example of using this module.

## Parameters

* `CORDW` - signed coordinate width (bits)
* `WORD` - machine word size (bits)
* `ADDRW` - address width (bits)
* `SHIFTW` - address shift width (bits)

For Isle, `CORDW` must be set to **16** and `WORD` must be set to **32**.

## Signals

### Input

* `clk` - clock
* `w`, `h` - canvas width and height (in pixels)
* `x`, `y` - pixel coordinates
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

* `addr` - address shift bits
* `pix_id` - pixel ID within word
* `clip` - high for pixel coordinate outside canvas

The `clip` allows you to avoid writes to vram where the pixel resides outside the canvas.
