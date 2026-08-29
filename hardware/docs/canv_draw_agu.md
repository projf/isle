# Canvas Draw Address Generation

The canvas draw address generation unit [[canv_draw_agu.v](../gfx/canv_draw_agu.v)] calculates the [vram](vram.md) address in a canvas buffer for drawing. Drawing addresses are derived from arbitrary coordinates and don't increase sequentially, so the approach used in the [display AGU](canv_disp_agu.md) is not appropriate here. [Earthrise](earthrise.md) uses an instance of this module.

This module has a four-cycle latency.

## Parameters

* `ADDRW` - address width (bits)
* `CORDW` - signed coordinate width (bits)
* `SHIFTW` - address shift width (bits)
* `WORD` - machine word size (bits)

There are also two important derived local parameters:

* `PIX_IDXW` - pixel index width (bits); derived from WORD
* `PIX_OFFSETW` - pixel offset width (bits)

The pixel offset is the offset of the pixel from the start of the canvas in units of pixels, as distinct from the address in vram (each location in vram can hold multiple pixels).

## Signals

### Input

* `clk` - clock
* `rst` - reset draw address calculation
* `en` - enable address calculation
* `canv_dims` - canvas dimensions (width in lower CORDW bits, height in upper CORDW bits)
* `pix_coord` - pixel coordinates (x in lower CORDW bits, y in upper CORDW bits)
* `vram_addr_base` - base word address of canvas in vram
* `addr_shift` - address shift bits
* `wraph` - horizontal draw wrap
* `wrapv` - vertical draw wrap

Using `en` you can halt the address calculation pipeline, which is useful when drawing is sharing a memory port with the CPU or another device.

`vram_addr_base` is the base _word_ address of the canvas buffer in vram. You can switch this at the start of a frame for double buffering. See also [display AGU](canv_disp_agu.md).

The address shift, `addr_shift`, determines how the pixel offset is split between vram address and pixel index.

Address shift is set based on the bits per pixel:

* 1 bit (2 colours): `addr_shift = 5`
* 2 bit (4 colours): `addr_shift = 4`
* 4 bit (16 colours): `addr_shift = 3`
* 8 bit (256 colours): `addr_shift = 2`

For example, 2 bits per pixel results in `addr_shift = 4`, giving you 16 pixels per 32-bit word (16 is 2^4).

The AGU supports horizontal and vertical wrapping via the `wraph` and `wrapv` signals. When enabled, wrapping operates over one width/height outside canvas dimensions. Wrapping is particularly helpful when scrolling a canvas.

For these examples, horizontal draw wrapping is enabled (`wraph` is high) and your canvas is 200 pixels wide. If your pixel coordinate is `x = -1`, the address will be calculated for `x = 199`. If you set `x = 210`, the address will be calculated for `x = 10`. However, if `x = 500`, then valid will still be low (false), even with draw wrap because it's more than one canvas width outside the edge of the canvas. This works in the same way for y coordinates (with `wrapv`).

`canv_dims`, `vram_addr_base` and `addr_shift` are not pipelined; you should hold these constant while drawing. `wraph` and `wrapv` can vary every cycle, which allows different parts of a drawing to have different wrap settings.

### Output

* `vram_addr` - vram word address
* `pix_idx` - pixel index within word
* `valid` - high for valid addresses

You should only trust the values of `vram_addr` and `pix_idx` when `valid` is high (1). Use this to control when drawing writes to vram; you can see an example in [Earthrise](earthrise.md). For example, if coordinates land outside the canvas (accounting for draw wrap), valid will be low. `valid` is low for the first three cycles after reset, so it's always safe to control memory writes with `valid`.

### Testing

There is a cocotb test bench [[canv_draw_agu.py](../tests/gfx/canv_draw_agu.py)] that exercises this module. For advice on running hardware tests, see [Isle Verilog Tests](../tests/README.md).
