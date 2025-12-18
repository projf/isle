# TMDS Encoder (DVI)

The **tmds_encoder** module [[verilog src](../gfx/tmds_encoder.v)] encodes a channel for DVI TMDS (transition-minimized differential signaling) suitable for output to a DVI or HDMI display. You encode each of the red, green, and blue channels separately using this module.

After encoding, the TMDS signals pass through architecture specific DVI generator module before being output: [[ECP5 Verilog src](../arch/ecp5/dvi_generator.v)] and [[XC7 Verilog src](../arch/xc7/dvi_generator.v)].

See the [Display](http://projectf.io/isle/display.html) blog post for more information on this module.

## Signals

The follow signals are used by the encoder (all in pixel clock domain).

### Input

* `clk_pix` - pixel (display) clock
* `rst_pix` - reset in pixel clock domain
* `din` - 8-bit colour data
* `ctrl_in` - 2-bit control data (channel 0 only, otherwise 0)
* `de` - data enable (from display controller)

Channel 0 encodes horizontal and vertical sync using the `ctrl_in` signal with values from the [display controller](display.md). For channel 1 and 2, `ctrl_in` should be zero:

```verilog
    .ch0_ctrl({disp_vsync, disp_hsync}),
    .ch1_ctrl(2'b00),
    .ch2_ctrl(2'b00),
```

### Output

* `tmds` - 10-bit encoded TMDS data

## Testing

There is a comprehensive test [[python src](../tests/gfx/tmds_encoder.py)] of the encoding using a Python model [[python src](../tests/gfx/tmds_model.py)].  For advice on running hardware tests, see [Isle Verilog Tests](../tests/README.md).
