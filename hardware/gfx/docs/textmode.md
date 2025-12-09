# Text Mode

The **textmode** module [[verilog src](../textmode.v)] displays text mode, loading character data and colour from [tram](../../mem/docs/tram.md).

Text mode includes a 2 KiB character ROM holding 128 characters for basic system functionality before additional storage is available; these characters cover Basic Latin and Block Elements. Text mode is currently limited by Isle's lack of storage; future versions will extend Unicode coverage and add support for full-width glyphs.

The latency of tram and font glyph retrieval is hidden by the cycles required to process one row of a glyph. You may see rendering issues if your font is less than 8 pixels wide.

See the [Text Mode](http://projectf.io/isle/text-mode.html) blog post for more information on this module.

## Modules

The textmode module depends on three other modules:

* [tram](../../mem/docs/tram.md) - holds Unicode code points and colours
* [font_glyph](font_glyph.md) - load font pixel data (embedded within _textmode_)
* [rom_sync](../../mem/docs/rom_sync.md) - holds core system font (embedded within _font\_glyph_)

## Parameters

* `CORDW` - signed coordinate width (bits)
* `WORD` - machine word size (bits)
* `ADDRW` - tram address width (bits)
* `CIDXW` - colour index width (bits)
* `CLUT_LAT` - CLUT latency (cycles)
* `FILE_FONT` - font glyph ROM file
* `FONT_COUNT` - number of glyphs in font ROM
* `GLYPH_HEIGHT` - glyph height (pixels)
* `GLYPH_WIDTH` - half-width glyph width (pixels)
* `TRAM_DEPTH` - tram depth (chars)
* `TRAM_LAT` - tram latency (cycles)

For Isle, `CORDW` must be set to **16**, `WORD` must be set to **32**, and `CIDXW` must be set to 4.

In tram, we pack two colours into a _word_ along with the Unicode code point; there isn't room for 8-bit (256 colours).

See [font_glyph](font_glyph.md) for details on font and glyph parameters.

## Signals

### Input

* `clk_pix` - pixel clock
* `rst_pix` - reset text mode state machine
* `frame_start` - frame start flag
* `(dx, dy)` - display position
* `scroll_offs` - tram address scroll offset
* `text_hres` - text width (chars)
* `text_vres` - text height (chars)
* `win_start` - text window start coords
* `win_end` - text window end coords
* `scale` - text scale
* `tram_data` - character data from tram

You can use `scroll_offs` to vertically scroll the text mode display. For example, if text mode is 84 characters wide, add 84 to `scroll_offs` to scroll down one line. The scroll offset is not signed. To scroll up one line, add one less than the height of the text mode; for example, if text mode is 84x24, set `scroll_offs` to 23*84.

The `win_start` and `win_end` inputs are a pair of signed 16-bit values, with the y-coordinate in the upper 16 bits. The `scale` input works in a similar way, with the vertical scale in the upper 16 bits and the horizontal scale in the lower 16 bits. When scaling text mode, the text doesn't wrap; adjust `text_hres` and `text_vres` to match the new scale if desired.

See [Canvas Display Address Generation](canv_disp_agu.md) for further discussion of windows and scaling.

### Output

* `tram_addr` - tram address (word)
* `pix` - pixel colour index
* `paint` - text mode painting enable

The colour `pix` should be painted when `paint` is enabled. The paint area is controlled by the text window coordinates, `win_start` and `win_end`.

The internal tram address is word-based, but the CPU and software don't see this.
