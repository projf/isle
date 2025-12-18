# XD

The **xd** [[verilog src](../sys/xd.v)] modules sends a flag (isolated pulse) from one clock domain to another. For example, the start of a frame is marked by the [display controller](display.md) in the _pixel clock_ domain; to use it in software we need it cross clock domains to the the _system_ clock domain.

This approach works reliably from _slow to fast_ and _fast to slow_ clock domain crossing, but only for isolated pulses of one clock cycle. For more complex clock domain crossing needs we use dual-port bram, as in the [vram](vram.v) module.

## Parameters

_This module has no parameters._

## Signals

### Input

* `clk_src` - source domain clock
* `clk_dst` - source domain clock
* `flag_src` - flag in source domain

### Output

* `flag_dst` - flag in destination domain
