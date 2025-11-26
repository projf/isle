# Font Glyph

The **font glyph** module [[verilog src](../font_glyph.v)] takes a Unicode code point and glyph line number and returns that line of font pixels from its internal ROM. This module is used by [textmode](textmode.md). This module has 4 cycles of latency and supports pipelining.

Font glyph is hardcoded to use a specific ROM that includes 128 glyphs across two Unicode blocks: Basic Latin and Block Elements. The ROM is loaded from [/res/fonts/system-font-rom.mem](/res/fonts/system-font-rom.mem). The ROM doesn't include white square, so the module uses light shade for the missing glyph (AKA tofu).

The internal ROM uses [rom_sync](../../mem/docs/rom_sync.md), which is usually inferred in bram.

A future version of font glyph will support a full range Unicode code points once Isle has storage to hold larger font ROMs.

## Parameters

* `FONT_COUNT` - number of glyphs in font ROM
* `FILE_FONT` - font glyph ROM file
* `HEIGHT` - glyph height (pixels)
* `LSB` - first font pixel in least significant bit
* `UCPW` - Unicode code point width (bits)
* `WIDTH` - glyph width (pixels)

The `LSB` param allows fonts with pixels stored in either direction. For GNU Unifont (used by the internal ROM), the first pixel is in the most significant bit, so `LSB=0`. If a font is 8 pixels wide, a ROM entry of `F0` will be 4 pixels on the left with `LSB=0`.

If `HEIGHT` isn't a power of 2 this module will infer a multiplier.

## Signals

The follow signals are used for line drawing. Isle drawing takes place in the system clock domain.

### Input

* `clk` - clock
* `rst` - reset
* `ucp` - Unicode code point
* `line_id` - glyph line to get

### Output

* `pix_line` - glyph pixel line
