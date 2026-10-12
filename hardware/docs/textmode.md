# Text Mode

The text mode module [[textmode.v](../gfx/textmode.v)] displays text using character data and colour from a dedicated memory: [tram](tram.md).

Text mode includes a 2 KiB character rom holding 128 characters for basic system functionality before additional storage is available; these characters cover [Basic Latin](https://en.wikipedia.org/wiki/Basic_Latin_(Unicode_block)) and [Block Elements](https://en.wikipedia.org/wiki/Block_Elements). Text mode is currently limited by Isle's lack of storage; future versions will extend Unicode coverage and add support for full-width glyphs.

Text mode fetches the next glyph while the previous one is being rendered. With the default Isle setup, this means the minimum glyph width is 8 pixels; if you set `GLYPH_WIDTH` to less than 8 pixels you'll have rendering issues. If `GLYPH_HEIGHT` isn't a power of 2, the [font_glyph](font_glyph.md) module may infer a multiplier.

Text mode also has one cycle of latency (`PIX_LAT`) to register outputs `pix` and `paint`. The module compensates for `PIX_LAT` and `CLUT_LAT` by starting drawing early.

See the [Text Mode](http://projectf.io/isle/text-mode.html) blog post for more information on this module.

## Hardware Scrolling

Vertically scrolling text mode is a very common operation, so we includes hardware scrolling support. For example, if you're appending a line to the bottom of the screen, hardware scrolling can move everything up one row and you only need change one row of text in tram.

Text rendering starts at `scroll_row` and continues down through tram, wrapping back to row 0 after the last row in memory. The valid range for `scroll_row` is 0 to TEXT_VRES-1.

## Dependencies

The textmode module depends on three other modules:

* [tram](tram.md) - holds Unicode code points and colours
* [font_glyph](font_glyph.md) - load font pixel data (embedded within _textmode_)
* [rom_sync](rom_sync.md) - holds core system font (embedded within _font\_glyph_)

## Parameters

* `ADDRW` - tram address width (bits)
* `CIDXW` - colour index width (bits)
* `CLUT_LAT` - CLUT latency (cycles)
* `CORDW` - signed coordinate width (bits)
* `FILE_FONT` - font glyph ROM file
* `FONT_COUNT` - number of glyphs in font ROM
* `GLYPH_HEIGHT` - glyph height (pixels)
* `GLYPH_WIDTH` - half-width glyph width (pixels)
* `TEXT_HRES` - text mode width (half-width chars)
* `TEXT_VRES` - text mode height (chars)
* `TRAM_LAT` - tram latency (cycles)
* `WORD` - machine word size (bits)

For Isle, `WORD` must be set to **32**, and `CIDXW` must be set to 4.

Text mode uses the first `TEXT_HRES × TEXT_VRES` words of tram and `ADDRW` must be wide enough to encompass this.

In tram, we pack Unicode code point and two 4-bit colours into a _word_. The Unicode standard limits the code point to 21 bits. See [tram](tram.md) for how the bits are packed into each word.

See [font glyph](font_glyph.md) for details on font and glyph parameters.

## Signals

### Input

* `clk_pix` - pixel clock
* `rst_pix` - reset text mode state machine
* `start` - start textmode rendering (before active painting area)
* `(dx, dy)` - display position
* `win_start` - text window start coords
* `win_end` - text window end coords
* `scale` - text scale
* `scroll_row` - first text row to display
* `tram_data` - character data from tram

The `win_start` and `win_end` inputs are a pair of signed 16-bit values, with the y-coordinate in the upper 16 bits. The `scale` input works in a similar way, with the vertical scale in the upper 16 bits and the horizontal scale in the lower 16 bits.

See [Canvas Display Address Generation](canv_disp_agu.md) for further discussion of windows and scaling.

### Output

* `tram_addr` - tram address (word)
* `pix` - pixel colour index
* `paint` - text mode painting enable

The colour `pix` should be painted when `paint` is enabled. The paint area is the intersection of the text area and window coordinates (`win_start` and `win_end`).
