# Display Controller

The **display** module [[verilog src](../gfx/display.v)] uses _display timings_ to generate sync signals and display coordinates.

The `MODE` parameter controls the display mode (resolution and refresh rate). The input pixel clock must match the mode to generate a valid display signal. For example, `MODE=2` is 1366x768 and requires a 72 MHz pixel clock.

Signed 16-bit coordinates are used throughout these designs for flexibility and consistency. Using signed coordinates allows negative coordinates for the blanking interval, with the origin of the display at (0,0) irrespective of the display mode.

See the [Display](http://projectf.io/isle/display.html) blog post for more information on this module.

## Parameters

* `CORDW` - signed coordinate width (bits)
* `MODE` - display mode (see below for supported modes)

For Isle, `CORDW` must be set to **16**.

## Signals

The follow signals are used to drive the display (all in pixel clock domain).

### Input

* `clk_pix` - pixel clock (frequency depends on display mode)
* `rst_pix` - reset display controller

### Output

* `hres, vres` - resolution of chosen display mode
* `dx, dy` - coordinates of current display pixel
* `hsync` - horizontal sync signal
* `vsync` - vertical sync signal
* `de` - data enable (low in blanking interval)
* `frame_start` - high for one cycle at frame start
* `line_start` - high for one cycle at line start

The resolution signals, `hres` and `vres`, allow logic to adapt to the screen resolution:

The frame and line flags allow you to take action each line or frame. For example, you might begin drawing when you receive a `frame_start` signal or start fetching pixel data at `line_start`.

## Mode

The display module includes five modes (pixel clock):

```
0 -  640 x 480 60 Hz (25.2 MHz)
1 - 1024 x 768 60 Hz (65 MHz)
2 - 1366 x 768 60 Hz (72 MHz)
3 -  672 x 384 60 Hz (25 MHz)
4 - 1280 x 720 60 Hz (74.25 MHz)
```

Additional display modes can easily be added to the case block at the end of the module. Remember to create a matching clock frequency for your mode.

For Isle, use the following display modes if possible:

* Widescreen display: 1366 x 768 (mode 2)
* 4:3 display: 1024 x 768 (mode 1)
* Simulation: 672 x 384 (mode 3)

### Static Display Mode

Mode could have been a signal to allow runtime resolution changes. However, this requires programmable PLLs, which is relatively complex and architecture dependent. By making MODE a a parameter we reduce complexity for developers and in logic. Meeting timing for display logic is vital as it only works at a particular frequency.

## Testing

There is a cocotb test bench [[python src](../tests/gfx/display.py)] that exercises this module with the included display modes. For advice on running hardware tests, see [Isle Verilog Tests](../tests/README.md).
