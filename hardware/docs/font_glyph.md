# Font Glyph

The **font_glyph** module [[verilog src](../gfx/font_glyph.v)] takes a Unicode code point and glyph line number and returns that line of font pixels from its internal ROM. This module is used by [textmode](textmode.md). This module has 4 cycles of latency and supports pipelining.

Font glyph is hardcoded to use a specific ROM that includes 128 glyphs across two Unicode blocks: Basic Latin and Block Elements. Isle loads the ROM with [system-font-rom.mem](../../../res/fonts/system-font-rom.mem). The ROM doesn't include white square, so the module uses light shade for the missing glyph (AKA tofu).

The internal ROM uses [rom_sync](rom_sync.md), which is usually inferred in bram.

A future version of font glyph will support a full range Unicode code points once Isle has storage to hold larger font ROMs.

## Parameters

* `FONT_COUNT` - number of glyphs in font ROM
* `FILE_FONT` - font glyph ROM file
* `HEIGHT` - glyph height (pixels)
* `LSB` - first font pixel in least significant bit
* `UCPW` - Unicode code point width (bits)
* `WIDTH` - glyph width (pixels)

The `FILE_FONT` parameter needs to be set to load the $readmemh format ROM at build time. Isle uses [/res/fonts/system-font-rom.mem](../../../res/fonts/system-font-rom.mem). Set `FONT_COUNT` to match the number of glyphs in the ROM, which is 128 for system-font-rom.mem.

The `LSB` param allows fonts with pixels stored in either direction. For GNU Unifont (used by the internal ROM), the first pixel is in the most significant bit, so `LSB=0`. If a font is 8 pixels wide, a ROM entry of `F0` will be 4 pixels on the left with `LSB=0`. If a font renders reflected, adjust `LSB`.

`UCPW` must be set to 21 to cover all possible Unicode code points.

If `HEIGHT` isn't a power of 2, this module may infer a multiplier.

## Signals

### Input

* `clk` - clock
* `ucp` - Unicode code point
* `line_id` - glyph line to get

### Output

* `pix_line` - glyph pixel line
