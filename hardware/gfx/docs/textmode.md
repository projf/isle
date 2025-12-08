# Textmode

The **textmode** module [[verilog src](../textmode.v)] displays text mode...

Text mode includes a 2 KiB character ROM holding 128 characters for basic system functionality before additional storage is available; these characters cover Basic Latin and Block Elements.

See the [Text Mode](http://projectf.io/isle/text-mode.html) blog post for more information on this module.

## Modules

Textmode depends on three modules:

* [tram](../../mem/docs/tram.md) - Unicode code points and colours
* [font glyph](font_glyph.md) - loads font pixel data
* [rom_sync](../../mem/docs/rom_sync.md) - sync rom holds core system font

## Operation

...

## Parameters

...

## Signals

### Input

...

### Output

...
