# Isle Line Drawing

The **line** module [[verilog src](../line.v)] draws lines with Bresenham's line algorithm. This implementation supports integer signed coordinates and draws towards increasing Y, swapping the input coordinates if necessary.

See the [2D Drawing](http://projectf.io/isle/2d-drawing.html) blog post for more information on the use of this module.

## Parameters

* `CORDW` - signed coordinate width (bits)

The [Earthrise](earthrise.md) 2D drawing engine uses a 12-bit coordinate. In future, Earthrise may switch to a 16-bit Q12.4 fixed-point format for sub-pixel precision.

## Signals

The follow signals are used for line drawing. Isle drawing takes place in the system clock domain.

### Input

* `clk` - clock
* `rst` - reset
* `start` - start line drawing
* `oe` - output enable
* `x0`, `y0` - line start coordinates
* `x1`, `y1` - line end coordinates

The `start` signal only works when if the module isn't already drawing. If you want to stop line drawing and start afresh you need to reset with `rst` then use `start`.

Output enable `oe` lets you pause line drawing, which is useful for multiplexing access to memory or for drawing more complex shapes where multiple lines are involved.

### Output

* `x`, `y` - line position (output coordinates)
* `lx` - first x-coordinate for this y
* `busy` - calculation in progress
* `valid` - output coordinates valid
* `fill` - ready for fill; current y complete (used by Earthrise)
* `done` - calculation complete (high for one tick)

`lx` is helpful when drawing filled triangles. When `fill` occurs, Earthrise can use `lx` or `x` depending on whether it needs the left or right pixel for this line. You can see this logic in the [Earthrise](earthrise.md) module.
