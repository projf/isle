# Textmode

The **textmode** module [[verilog src](../textmode.v)] displays text mode...

Text mode includes a 2 KiB character ROM holding 128 characters for basic system functionality before additional storage is available; these characters cover Basic Latin and Block Elements.

See the [Text Mode](http://projectf.io/isle/text-mode.html) blog post for more information on this module.

## Modules

Textmode depends on three modules:

* [tram](../../mem/docs/tram.md) - Unicode code points and colours
* [font glyph](font_glyph.md) - loads font pixel data
* [rom_sync](../../mem/docs/rom_sync.md) - sync rom holds core system font

## Pipeline

1. Set tram address (1 cycle)
2. Load UCP and colours from tram (1 cycle)
3. Load pixels from font_glyph using UCP (4 cycles)
   - repeat for each line of pixels in glyph (typically 16)
4. Output the pixel colour index (1 cycle)

Setting the tram address and loading data from tram takes 2 cycles, but these steps can overlap with other steps, so don't contribute to the overall latency.

We also need to consider that colour lookup (CLUT) introduces latency, so we need to output `pix` (pixel colour index) `CLUT_LAT` cycles before the display coordinate.
