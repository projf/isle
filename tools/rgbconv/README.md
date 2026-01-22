# RGB Converter

Isle uses 15-bit colour, RGB555, but most contemporary systems use 24-bit RGB888 colour. The **rgbconv** tool converts to/from 15-bit and 24-bit string formats. It's written in Python and reads from stdin and outputs to stdout.

Learn more about [Isle Display Modes](http://projectf.io/isle/display-modes.html), including 15-bit colour.

The following 24-bit formats are supported:

* `RRGGBB`
* `#RRGGBB`
* `0xRRGGBB`

The following 15-bit formats are supported:

* `ABCD` - packed 15-bit hex value
* `0xABCD`
* `RGB(r,g,b)` - r,g,b values 0-31

Example session:

```shell
$ tools/rgbconv/rgbconv.py
Isle RGB Colour Converter - Press ctrl-D to exit
0C43
#181018 - 0C43 - rgb(03, 02, 03)
rgb(31,31,31)
#FFFFFF - 7FFF - rgb(31, 31, 31)
#1098b1
#1098B1 - 0A76 - rgb(02, 19, 22)
0A76
#109CB5 - 0A76 - rgb(02, 19, 22)
```