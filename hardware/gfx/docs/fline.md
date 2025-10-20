# Fast Line Drawing

The **fline** module [[verilog src](../fline.v)] draws horizontal lines. This implementation supports signed integer coordinates.

The primary purpose of fast line is to accelerate the drawing of horizontal lines used in fills. Consecutive horizontal pixels are found at the same memory address in vram and can be written in one operation. For example, in 16-colour mode there are eight pixels in each 32-bit vram location. Support for writing multiple pixels in one memory operation will be handled in [Earthrise](earthrise.md).

## Parameters

* `CORDW` - signed coordinate width (bits)

[Earthrise](earthrise.md) uses 12-bit integer coordinates. In future, Earthrise may switch to a 16-bit Q12.4 fixed-point format for sub-pixel precision.

## Signals

The follow signals are used for fast line drawing. Isle drawing takes place in the system clock domain.

### Input

* `clk` - clock
* `rst` - reset
* `start` - start line calculation
* `oe` - output enable
* `x0` - horizontal line start coordinate
* `x1` - horizontal line end coordinate

The `start` signal only works when if the module isn't already calculating. If you want to stop the calculation and start afresh you need to reset with `rst` then use `start`.

Output enable `oe` lets you pause the fast line calculation, which is useful for multiplexing access to memory or for drawing shapes (such as triangles) where multiple lines are involved.

### Output

* `x` - line position (output coordinate)
* `busy` - calculation in progress
* `valid` - output coordinates valid
* `done` - calculation complete (high for one tick)
