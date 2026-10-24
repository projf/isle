# Text Mode Ram

The text mode ram (tram) module [[tram.v](../mem/tram.v)] holds text mode characters in block ram (bram). The default Isle tram design is 8 KiB as 2K x 32 bit, which supports up to 80x25 (640x400) or 84x24 (672x384)characters. The tram is byte write. The [text mode](textmode.md) module connects to tram to retrieve character data for display.

The tram holds one 32-bit word per character consisting of (LSB to MSB):

* 21 bits Unicode code point (UCP)
* 3 bits unused (reserved for future use)
* 4 bits foreground colour index (FG)
* 4 bits background colour index (BG)

```
|31  28|27  24|23  21|20                  0|
|------|------|------|---------------------|
| BG   | FG   |  -   |        UCP          |
|------|------|------|---------------------|
```

The CPU can write the Unicode code point, together with foreground and background colours, in a single word. By writing a byte to the upper 8 bits, the CPU can change the colours of an existing character.

The system (sys) port is for reading and writing characters. The system port is designed for interfacing with a CPU and is in the system clock domain. The display (disp) port is for reading character data for display output and is in the pixel clock domain.

The separate system and displays ports avoid contention between the CPU and display logic and form part of the clock-domain crossing (CDC) architecture that allows the system and display clocks to run independently.

## Parameters

* `ADDRW` - address width (bits)
* `BYTE` - machine byte size (bits)
* `BYTE_CNT` - bytes in machine word
* `FILE_TXT` - optional initial text to load
* `WORD` - machine word size (bits)

For Isle, `ADDRW` should be set to **11**, for an 8 KiB tram (see intro, above).

The tram takes a `FILE_TXT` parameter, which allows an initial $readmemh format [textmap](../../res/textmaps/) to be loaded at build time. Loading a textmap at build time is useful for testing without a CPU.

## Signals

The tram is dual port, with a system and display port in different clock domains. The signal interface is similar to [vram](vram.md), except write enable per byte via `we_sys` in tram.

### Input

* `clk_sys` - system clock
* `clk_pix` - pixel clock (frequency depends on [display mode](display_sync_gen.md))
* `we_sys` - system write enable (byte mask)
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

There is a cocotb test bench [[tram.py](../tests/mem/tram.py)] that exercises this module. For advice on running hardware tests, see [Isle Verilog Tests](../tests/README.md).
