# Colour Lookup Table

The colour lookup table module [[clut.v](../mem/clut.v)] maps palette indexes to colours. This approach is commonly referred to as [Indexed Colour](https://en.wikipedia.org/wiki/Indexed_color) (Wikipedia).

For example, in 16 colour mode each pixel colour in [vram](vram.md) is represented by a 4-bit colour index. When we come to display that pixel we read the colour index from vram, say **6**, then use the clut to map that to an RGB colour. Isle uses 15-bit RGB555 colours, such as (31, 31, 00), which is bright yellow.

The clut is word-addressed by the CPU; one 32-bit word maps to a single palette entry. Software must use store word (`sw`) to update palette entries; store half (`sh`) and store byte (`sb`) are ignored. When reading a palette entry, the low `DATAW` bits contain the colour, while the remaining upper bits are zero.

The system (sys) port is for reading and writing palette entries. The system port is designed for interfacing with a CPU and is in the system clock domain. The display (disp) port is for looking up colours for display output and is in the pixel clock domain.

The separate system and display ports avoid contention between the CPU and display logic and form part of the clock-domain crossing (CDC) architecture that allows the system and display clocks to run independently. Block ram handles the CDC for us.

## Parameters

* `ADDRW` - address width (bits)
* `DATAW` - data width (bits)
* `FILE_PAL` - optional initial palette to load

The address width determines the number of palette entries. The data width depends on the output colour. Isle supports 256 15-bit colours (RGB555), so uses `DATAW=15` and `ADDRW=8`.

The clut takes a `FILE_PAL` parameter, which allows an initial $readmemh format palette to be loaded at build time. Isle includes several palettes to get you started, see [Colour Palettes](../../docs/colour-palettes.md) for details.

## Signals

The clut is dual port, with a system and display port in different clock domains.

### Input

* `clk_sys` - system clock
* `clk_pix` - pixel clock (frequency depends on [display mode](display_sync_gen.md))
* `we_sys` - system write enable
* `re_sys` - system read enable
* `addr_sys` - system word address
* `din_sys` - system data in
* `addr_disp` - display word address

### Output

* `dout_sys` - system data out
* `dout_disp` - display data out

## Latency

* **system port** - 1 cycle read latency
* **display port** - 2 cycle read latency

The system port has 1 cycle of latency because the CPU expects to read data the cycle after it makes the request. If timing becomes an issue in the system clock domain, we could add an output register, but we would need to update system bus logic to make the CPU wait.

The display port is driven by the pixel clock, which is usually a higher frequency than the system clock. We add an additional output register on the display port to improve timing in the pixel clock domain. Additional latency has no impact on display performance.

## Testing

There is a cocotb test bench [[clut.py](../tests/mem/clut.py)] that exercises this module. For advice on running hardware tests, see [Isle Verilog Tests](../tests/README.md).
