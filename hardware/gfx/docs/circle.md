# Circle Drawing

The **circle** module [[verilog src](../circle.v)] provides the x and y distances to draw a circle with the midpoint circle algorithm. This implementation supports signed integer coordinates. See [Earthrise](earthrise.md) for an example drawing complete circles with this module.

See the [2D Drawing](http://projectf.io/isle/2d-drawing.html) blog post for more information on the use of this module.

## Parameters

* `CORDW` - signed coordinate width (bits)

The [Earthrise](earthrise.md) 2D drawing engine uses a 12-bit coordinate. In future, Earthrise may switch to a 16-bit Q12.4 fixed-point format for sub-pixel precision.

## Signals

The follow signals are used for circle drawing. Isle drawing takes place in the system clock domain.

### Input

* `clk` - clock
* `rst` - reset
* `start` - start circle calculation
* `oe` - output enable
* `r0` - circle radius

The `start` signal only works when if the module isn't already calculating. If you want to stop the calculation and start afresh you need to reset with `rst` then use `start`.

Output enable `oe` lets you pause the calculation, so you can use the `xa`, `ya` distances to calculate the circle coordinates.

### Output

* `xa`, `ya` - x and y distances
* `lx` - first x-coordinate for this y
* `busy` - calculation in progress
* `valid` - output coordinates valid
* `done` - calculation complete (high for one tick)

The output distances `xa`, `ya` are relative to the centre coordinate.
