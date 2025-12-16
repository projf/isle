# Isle Resources

Resources for use by Isle hardware. Most are in Verilog $readmemh format.

## Bitmaps

* [Crocus Bitmap](bitmaps/crocus/) - 332x192 16-colour bitmap
* [Latency Bitmap](bitmaps/latency/) - 672x384 4-colour bitmap

## Drawings

Earthrise drawings in assembler format using extension `.eas`. Use [erasm](../tools/erasm/) to assemble them.

* [All Shapes](drawings/all-shapes.eas) - a test drawing using many Earthrise features
* [Basic Test](drawings/basic-test.eas) - a few small shapes for end-to-end testing
* [16 Squares](drawings/16-squares.eas) - 16 different coloured squares
* [Doc Examples](drawings/doc-examples.eas) - examples from [Earthrise Programming](../docs/earthrise-programming.md)
* [Large Shapes](drawings/large-shapes.eas) - some large shapes for testing edge cases

The _All Shapes_ and _Basic Test_ drawings are also available pre-compiled in $readmemh format.

## Fonts

* [System Font ROM](fonts/system-font-rom.mem) - 128 8x16 pixel glyphs for internal ROM (GNU Unifont)

_Fonts have their own licences; see font file header for details._

## Palettes

See [Colour Palettes](../docs/colour-palettes.md) for details including reference images.

## Textmaps

Test textmaps for text mode. See [tram](../hardware/mem/docs/tram.md) docs for details on format.

* [ROM Glyphs](textmaps/rom-84x24.mem) - tests all 128 internal ROM glyphs
* [Edge Tests](textmaps/edge-84x24.mem) - test display edge cases
* [Hello World](textmaps/hello-84x24.mem) - greetings from text mode
