# Canvas Display Address Generation

The canvas display address generation unit [[canv_disp_agu.v](../gfx/canv_disp_agu.v)] calculates the [vram](vram.md) address within a canvas buffer for display output.

The address calculation supports different colour depths, canvas positioning, and scaling. This module supports pipelining.

See the [Bitmap Graphics](http://projectf.io/isle/bitmap-graphics.html) blog post for more information on this module.

## Parameters

* `ADDRW` - address width (bits)
* `CLUT_LAT` - clut display read latency (cycles; min=1)
* `CORDW` - signed coordinate width (bits)
* `SHIFTW` - address shift width (bits)
* `VRAM_LAT` - vram display read latency (cycles; min=1)
* `WORD` - machine word size (bits)

## Signals

### Input

* `clk_pix` - pixel clock
* `rst_pix` - reset canvas address calculation
* `start` - start address calculation (before active painting area)
* `line_start` - line start flag
* (`dx`, `dy`) - display position
* `vram_addr_base` - base word address of canvas in vram
* `addr_shift` - address shift bits (for colour depth)
* `canv_dims` - canvas dimensions (width in lower CORDW bits, height in upper CORDW bits)
* `scale` - canvas scale
* `scroll_coord` - canvas scroll coords
* `win_start` - canvas window start coords
* `win_end` - canvas window end coords

Several of these input signals come from the [display sync generator](display_sync_gen.md).

Ensure you trigger `start` before the active painting area, when `dy < 0`. You should also allow canvas signals to settle for at least **2 cycles** before triggering `start`, to allow for the scroll multiplication to complete. [dev_display](dev_display.md) handles this by calling start the display line after copying hwreg.

The position of the canvas on the display is set by the window start `win_start` and end `win_end` signals. While canvas horizontal and vertical dimensions and scale are controlled by `canv_dims` and `scale`. These signals are discussed in more detail below.

`vram_addr_base` is the base _word_ address of the canvas buffer in vram. You can switch this at the start of a frame for double buffering. Or even mid-way through a frame to combine different buffers to form a display.

The `VRAM_LAT` and `CLUT_LAT` parameters account for latency when retrieving data from [vram](vram.md) and when looking up the colour in the [clut](clut.md). For Isle, they should both be set to 2, matching the latency of the vram and clut hardware. See [display pipeline](#display-pipeline) for further explanation.

The address shift, `addr_shift`, determines how the raw pixel address is split between vram address and the pixel index. Because the maximum address shift is 5, the `SHIFTW` parameter is set to 3.

Address shift is set based on the bits per pixel:

* 1 bit: `addr_shift = 5`
* 2 bit: `addr_shift = 4`
* 4 bit: `addr_shift = 3`
* 8 bit: `addr_shift = 2`

For example, 2 bits per pixel results in `addr_shift = 4`, giving you 16 pixels per 32-bit word (16 is 2^4).

The width of the canvas must be an integer number of words. The number of pixels in a word depends on the colour depth:

* 1 bit: 32
* 2 bit: 16
* 4 bit: 8
* 8 bit: 4

For example, with a 4-bit (16 colour) canvas, 328 is a valid width (divisible by 8), but it is invalid for a 2-bit canvas (328 is not divisible by 16). You'll see bitmap rendering issues if you use an invalid canvas width.

### Output

* `vram_addr` - vram word address
* `pix_idx` - pixel index within word
* `paint` - canvas painting enable

The three outputs are the latency corrected `vram_addr`, `pix_idx`, and `paint` signals.

Our [vram](vram.md) has a 32-bit data bus, but a pixel is 1-8 bits wide. The `pix_idx` signal tells the display where in the data word the pixel is. For example, the third 4-bit pixel in a word would have a pix_idx of 2.

The paint signal tells you when canvas pixels should be rendered to the display. The canvas doesn't necessarily cover the whole window, and the window doesn't necessarily cover the whole display, so we need to know when to paint it.

_NB. This module doesn't perform any memory boundary checks._

## Window Position and Scale

```
|-------------------------------|
|  win_start            display |
|        *----------|           |
|        |  canvas  |           |
|        |          |           |
|        |----------*           |
|                    win_end    |
|                               |
|-------------------------------|
```

The `win_start` and `win_end` inputs are a pair of signed values (of width CORDW), with the y-coordinate in the upper CORDW bits. The `canv_dims` and `scale` inputs work in a similar way, with the vertical scale in the upper CORDW bits and the horizontal scale in the lower CORDW bits.

For example, a 256x192 canvas at 2x scale centred on 640x480 display:

```
2 x 256x192 = 512x384

win_start x-coordinate: (640-512)/2 = 64 (0x0040)
win_start y-coordinate: (480-384)/2 = 48 (0x0030)
win_start: 0x00300040

win_end x-coordinate: 64+512 = 576 (0x0240)
win_end y-coordinate: 48+384 = 432 (0x01B0)
win_end: 0x01B00240

canv_dims x-coordinate: 256 (0x0100)
canv_dims y-coordinate: 192 (0x00C0)
canv_dims: 0x00C00100

scale:  0x00020002
```

The module correctly handles canvases that are too small or large for the window.

[Text mode](textmode.md) windows work in the same way.

The registered signals `scale_x_minus` and `scale_y_minus` are the scaling factors with 1 subtracted to improve the timing slack of the scale counters. For a scale factor of 1x, these _minus signals have a value of 0.

## Scrolling

Canvases support scrolling, which is a efficient way to pan an image or background. The canvas bitmap data isn't changed, we just change which part of the canvas we're displaying.

Isle canvases also wrap, so a small amount of vram can create the illusion of a vast image. When the user scrolls the image, we just need to draw one column (for horizontal scrolling) or line (for vertical scrolling) of pixels to memory, rather than rerendering the whole image.

Scrolling is controlled by `scroll_coord`, a a pair of unsigned values, one for the Y scroll position and one for the X. For example, if `CORDW=16` and you want the top-left pixel in the window to be from canvas pixel (Y=5, X=42), `scroll_coord` would be set to `0x0005002A`.

NB. scroll coordinates must fit within the canvas; so, greater or equal to zero, and less than canvas width/height.

## Display Pipeline

The bitmap display pipeline has three stages:

1. Canvas Display AGU (this module) - calculates vram address
2. [vram](vram.md) - returns pixel data
3. [clut](clut.md) - looks up pixel colour

This process takes several clock cycles. If we don't account for latency, the pixel would be displayed in the wrong position (too far to the right). The vram and clut modules use bram with additional output registers, hence taking two cycles from address generation to receiving data.

Our display controller begins each line with the horizontal blanking interval. This gives us time to prepare the pipeline for the first pixel, even if it's at x=0.

## Testing

There is a cocotb test bench [[canv_disp_agu.py](../tests/gfx/canv_disp_agu.py)] that exercises this module. For advice on running hardware tests, see [Isle Verilog Tests](../tests/README.md).
