# Canvas Display Address Generation

The canvas display address generation unit **canv_disp_agu** [[verilog src](../canv_disp_agu.v)] calculates the [vram](../../mem/docs/vram.md) address in a canvas buffer for display.

The address calculation supports different colour depths, canvas positioning, and scaling. This module has 2 cycles of latency and avoids multiplication.

See the [Bitmap Graphics](http://projectf.io/isle/bitmap-graphics.html) blog post for more information on this module.

## Parameters

* `CORDW` - signed coordinate width (bits)
* `WORD` - machine word size (bits)
* `ADDRW` - address width (bits)
* `BMAP_LAT` - latency for AGU + VRAM + CLUT
* `SHIFTW` - address shift width (bits)

For Isle, `CORDW` must be set to **16** and `WORD` must be set to **32**.

## Signals

### Input

* `clk_pix` - pixel clock
* `rst_pix` - reset canvas address calculation
* `frame_start` - frame start flag
* `line_start` - line start flag
* `dx` - horizontal display position
* `dy` - vertical display position
* `addr_base` - canvas base address
* `addr_shift` - address shift bits (for colour depth)
* `win_start` - canvas window start coords
* `win_end` - canvas window end coords
* `scale` - canvas scale

Several of these input signals come from the [display controller](display.md).

The position of the canvas on the display is set by the window start `win_start` and end `win_end` signals, while horizontal and vertical scale are controlled by `scale`. These signals are discussed in more detail below.

`addr_base` is the base address of the canvas buffer in vram. You can switch this at the start of a frame for double buffering. Or even mid-way through a frame to combine different buffers to form a display.

The `BMAP_LAT` parameter corrects for end-to-end bitmap latency in calculating the address, retrieving data from vram, and looking the colour up in the CLUT. For Isle this should be set to 6. See [Display Pipeline](#display-pipeline) for further explanation.

The address shift, `addr_shift`, determines how the raw pixel address is split between vram address and pixel index.

Address shift is set based on the bits per pixel:

* 1 bit: `addr_shift = 5`
* 2 bit: `addr_shift = 4`
* 4 bit: `addr_shift = 3`
* 8 bit: `addr_shift = 2`

For example, 2 bits per pixel mean you have 16 pixels per 32-bit word, and 16 is 2^4.

### Output

* `addr` - pixel memory address
* `pidx` - pixel index within word
* `paint` - canvas painting enable

The three outputs are the latency corrected `addr_pix`, `pidx`, and `paint` signals.

Our [vram](vram.md) has a 32-bit data bus, but a pixel is 1-8 bits wide. The `pidx` signal tells the display where in the data word the pixel is. For example, the third 4-bit pixel in a word would have a pidx of 2.

The paint signal tells you when canvas pixels should be output for display. The canvas doesn't necessarily cover the whole screen, so we need to know the right time to paint it.

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

The `win_start` and `win_end` inputs are a pair of signed 16-bit values, with the y-coordinate in the upper 16 bits. The `scale` input works in a similar way, with the vertical scale in the upper 16 bits and the horizontal scale in the lower 16 bits.

For example, a 256x192 canvas at 2x scale centred on 640x480 display:

```
2 x 256x192 = 512x384

win_start x-coordinate: (640-512)/2 = 64 (0x0040)
win_start y-coordinate: (480-384)/2 = 48 (0x0030)
win_start: 0x00300040

win_end x-coordinate: 64+512 = 576 (0x0240)
win_end y-coordinate: 48+384 = 432 (0x01B0)
win_end: 0x01B000240

scale:  0x00020002
```

## Display Pipeline

The bitmap display pipeline has three stages:

1. Canvas Display AGU (this module) - calculates vram address
2. [VRAM](../../mem/docs/vram.md) - returns pixel data
3. [CLUT](../../mem/docs/clut.md) - looks up pixel colour

This process takes several clock cycles. If we don't account for latency, the pixel would be displayed in the wrong position (too far to the right). VRAM and CLUT use brams with output registers, hence taking two cycles from address generation to receiving data.

Our display controller begins each line with the horizontal blanking internal. This gives us time to prepare the pipeline for the the first pixel, even if it's at x=0.

### Testing

There is a cocotb test bench [[python src](../test/canv_disp_agu.py)] that exercises this module. For advice on running hardware tests, see [Isle Verilog Tests](../../../docs/verilog-tests.md).
