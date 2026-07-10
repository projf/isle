# Canvas Draw Address Generation

The canvas draw address generation unit [[canv_draw_agu.v](../gfx/canv_draw_agu.v)] calculates the [vram](vram.md) address in a canvas buffer for drawing. Drawing addresses are derived from arbitrary coordinates and don't increase sequentially, so the approach used in the [display AGU](canv_disp_agu.md) is not appropriate here.

This module supports pipelining. [Earthrise](earthrise.md) uses an instance of this module.

## Parameters

* `CORDW` - signed coordinate width (bits)
* `WORD` - machine word size (bits)
* `ADDRW` - address width (bits)
* `SHIFTW` - address shift width (bits)

## Signals

### Input

* `clk` - clock
* `w`, `h` - canvas width and height (in pixels)
* `x`, `y` - pixel coordinates
* `vram_addr_base` - base word address of canvas in vram
* `addr_shift` - address shift bits

`vram_addr_base` is the base _word_ address of the canvas buffer in vram. You can switch this at the start of a frame for double buffering. See also [display AGU](canv_disp_agu.md).

The address shift, `addr_shift`, determines how the raw pixel address is split between vram address and pixel index.

Address shift is set based on the bits per pixel:

* 1 bit: `addr_shift = 5`
* 2 bit: `addr_shift = 4`
* 4 bit: `addr_shift = 3`
* 8 bit: `addr_shift = 2`

For example, 2 bits per pixel mean you have 16 pixels per 32-bit word, and 16 is 2^4.

### Output

* `vram_addr` - vram word address
* `pix_idx` - pixel index within word
* `clip` - high for pixel coordinate outside canvas

The `clip` allows you to avoid writes to vram where the pixel resides outside the canvas.
