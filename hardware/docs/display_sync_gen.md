# Display Sync Signal Generation

The sync signal generation module [[display_sync_gen.v](../gfx/display_sync_gen.v)] generates display sync signals (horizontal and vertical blanking) and coordinates.

The `DISPLAY_MODE` parameter controls the display mode (resolution and refresh rate). The input pixel clock _must_ be correct for the display mode to generate a valid display signal. For example, `DISPLAY_MODE=2` is 1366x768 and requires a 72 MHz pixel clock. See [display_modes.vh](../include/display_modes.vh) for supported display modes, including 1024x768, 1366x768, and 1280x720.

Signed 16-bit coordinates are used throughout Isle for flexibility and consistency. Using signed coordinates allows negative coordinates for the blanking interval, with the origin of the display at (0,0) irrespective of the display mode.

See the [Display Controller](http://projectf.io/isle/display-controller.html) blog post to learn about this module in context.

## Parameters

* `CORDW` - signed coordinate width (bits)
* `DISPLAY_MODE` - display mode (see [display_modes.vh](../include/display_modes.vh))

## Signals

The follow signals are used to drive the display (all in pixel clock domain).

### Input

* `clk_pix` - pixel clock (frequency depends on display mode)
* `rst_pix` - reset display controller

### Output

* `dx, dy` - coordinates of current display pixel
* `hsync` - horizontal sync signal
* `vsync` - vertical sync signal
* `de` - data enable (low in blanking interval)
* `frame_start` - high for one cycle at frame start
* `line_start` - high for one cycle at line start

The frame and line flags allow you to take action each line or frame. For example, you might begin drawing when you receive a `frame_start` signal or start fetching pixel data at `line_start`. These flags can be made available in the system clock domain using [xd.v](xd.md).

### Static Display Mode

Display mode could have been a signal to allow runtime resolution changes. However, this requires programmable PLLs, which are architecture dependent and relatively complex. By making DISPLAY_MODE a parameter we reduce complexity for developers and in logic. Meeting timing for a particular display mode is vital as it only works at one frequency.

## Testing

There is a cocotb test bench [[hardware/tests/gfx/display_sync_gen.py](../tests/gfx/display_sync_gen.py)] that exercises this module with the included display modes. For advice on running hardware tests, see [Isle Verilog Tests](../tests/README.md).
