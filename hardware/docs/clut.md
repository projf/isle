# CLUT

The **clut** (Colour Lookup Table) module [[verilog src](../mem/clut.v)] maps palette indexes to colours.

For example, in 16 colour mode each pixel in [vram](vram.md) is represented by a 4-bit colour index. When we come to display that pixel we read the colour index from vram, say **6**, then use the clut to map that to a 15-bit RGB555 colour such as (31, 31, 00), which is bright yellow.

The system (sys) port is for reading and writing palette entries. The system port is designed for interfacing with a CPU and is in the system clock domain. The display (disp) port is for looking up colours for display output and is in the pixel clock domain.

The separate system and displays ports avoid contention between the CPU and display logic and form part of the clock-domain crossing (CDC) architecture that allows the system and display clocks to run independently.

## Parameters

* `ADDRW` - address width (bits)
* `DATAW` - data width (bits)
* `FILE_PAL` - optional initial palette to load

For Isle, `DATAW` must be set to **15** and `ADDRW` should be set to **8**.

The clut takea a `FILE_PAL` parameter, which allows an initial $readmemh format palette to be loaded at build time. Isle includes several palettes to get you started, see [Colour Palettes](../../../docs/colour-palettes.md) for details.

## Signals

The clut is dual port, with a system and display port in different clock domains.

### Input

* `clk_sys` - system clock
* `clk_pix` - pixel clock (frequency depends on [display](display.md) mode)
* `we_sys` - system write enable
* `addr_sys` - system word address
* `din_sys` - system data in
* `addr_disp` - display word address

_NB. The CLUT doesn't support byte-write; a single CPU word maps to each palette entry._

### Output

* `dout_sys` - system data out
* `dout_disp` - display data out

## Latencies

* **system port** - 1 cycle read latency
* **display port** - 2 cycle read latency

The display port has a higher latency because of the output register to improve timing.

## Testing

There is a cocotb test bench [[python src](../tests/clut.py)] that exercises this module. For advice on running hardware tests, see [Isle Verilog Tests](../tests/README.md).

Most of the complexity depends on the dual-port bram implementation, which isn't visible with this inferred memory design.
