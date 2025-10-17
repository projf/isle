# Canvas Draw Address Generation

The canvas draw address generation unit **canv_draw_agu** [[verilog src](../canv_draw_agu.v)] calculates the [vram](../../mem/docs/vram.md) address in a canvas buffer for drawing. Drawing addresses are based on coordinates and don't increase sequentially, so the approach used in the [display AGU](canv_disp_agu.md) is not appropriate here.

_to do_
