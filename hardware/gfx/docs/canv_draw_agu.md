# Canvas Draw Address Generation

The canvas draw address generation unit **canv_draw_agu** [[verilog src](../canv_draw_agu.v)] calculates the [vram](../../mem/docs/vram.md) address in a canvas buffer for drawing. Drawing addresses are based on coordinates and don't increase sequentially, so the approach used in the [display AGU](canv_disp_agu.md) is not appropriate here.

## Parameters

* `CORDW` - signed coordinate width (bits)
* `WORD` - machine word size (bits)
* `ADDRW` - address width (bits)
* `SHIFTW` - address shift width (bits)

For Isle, `CORDW` must be set to **16** and `WORD` must be set to **32**.

## Signals

### Input

* `clk` - clock

_to do_
