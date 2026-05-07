# Display Timings

The **display timings** module [[verilog src](../gfx/display_timings.v)] generates sync signals and display coordinates.

The `MODE` parameter controls the display mode (resolution and refresh rate). The input pixel clock must match the mode to generate a valid display signal. For example, `MODE=2` is 1366x768 and requires a 72 MHz pixel clock. See [[display_modes.vh](../include/display_modes.vh)] for supported modes.

Signed 16-bit coordinates are used throughout these designs for flexibility and consistency. Using signed coordinates allows negative coordinates for the blanking interval, with the origin of the display at (0,0) irrespective of the display mode.

See the [Display](http://projectf.io/isle/display.html) blog post for more information on this module.

## Parameters

* `CORDW` - signed coordinate width (bits)
* `MODE` - display mode (see below for supported modes)

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

The frame and line flags allow you to take action each line or frame. For example, you might begin drawing when you receive a `frame_start` signal or start fetching pixel data at `line_start`.

### Static Display Mode

Mode could have been a signal to allow runtime resolution changes. However, this requires programmable PLLs, which is relatively complex and architecture dependent. By making MODE a a parameter we reduce complexity for developers and in logic. Meeting timing for display logic is vital as it only works at a particular frequency.

## Testing

There is a cocotb test bench [[python src](../tests/gfx/display.py)] that exercises this module with the included display modes. For advice on running hardware tests, see [Isle Verilog Tests](../tests/README.md).
