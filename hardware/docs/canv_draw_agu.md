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
* `canv_dims` - canvas dimensions (width in lower 16 bits, height in upper 16 bits)
* `pix_coord` - pixel coordinates (x in lower 16 bits, y in upper 16 bits)
* `vram_addr_base` - base word address of canvas in vram
* `addr_shift` - address shift bits
* `draw_wrap` - controls draw wrapping

`vram_addr_base` is the base _word_ address of the canvas buffer in vram. You can switch this at the start of a frame for double buffering. See also [display AGU](canv_disp_agu.md).

The address shift, `addr_shift`, determines how the raw pixel address is split between vram address and pixel index.

Address shift is set based on the bits per pixel:

* 1 bit: `addr_shift = 5`
* 2 bit: `addr_shift = 4`
* 4 bit: `addr_shift = 3`
* 8 bit: `addr_shift = 2`

For example, 2 bits per pixel mean you have 16 pixels per 32-bit word, and 16 is 2^4.

Setting `draw_wrap` high enables draw wrapping for one width/height outside canvas dimensions. One good use for draw wrapping is when scrolling your canvas.

For these examples, draw wrapping is enabled and your canvas is 200 pixels wide. If your pixel coordinate is `x = -1`, the address will be calculated for `x = 199`. If you set `x=210`, the address will be calculated for `x = 10`. However, if `x=500`, then it'll still clip, even with `draw_wrap` because it's more than one canvas width outside the edge of the canvas. This works in the same way for y coordinates.

### Output

* `vram_addr` - vram word address
* `pix_idx` - pixel index within word
* `clip` - high for pixel coordinate outside canvas (but see `draw_wrap`, above)

clip` allows you to avoid bad writes vram when coordinates are invalid. You should only trust the values of `vram_addr` and `pix_idx` when clip is low (0).

### Testing

There is a cocotb test bench [[canv_draw_agu.py](../tests/gfx/canv_draw_agu.py)] that exercises this module. For advice on running hardware tests, see [Isle Verilog Tests](../tests/README.md).
