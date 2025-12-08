# TRAM

The **tram** (text mode ram) [[verilog src](../tram.v)] module holds text mode characters in block ram (bram). The default Isle tram design is 8 KiB as 2K x 32 bit, which supports 84x24 (672z384) and 80x25 (640x400). The tram is byte write.

The tram holds 32-bit word per character consisting of (LSB to MSB):

* 21 bits Unicode code point
* 3 bits unused (reserved for future use)
* 4 bits foreground colour index
* 4 bits background colour index

The CPU can write the Unicode code point, together with foreground and background colours, in a single word. By writing a byte to the upper 8 bits, the CPU can change the colours of an existing character.

## Parameters

* `BYTE` - machine byte size (bits)
* `BYTE_CNT` - bytes in machine word
* `WORD` - machine word size (bits)
* `ADDRW` - address width (bits)
* `FILE_TXT` - optional initial text to load

The optional `FILE_TXT` parameter allows $readmemh format text to be loaded at build time; this is mostly useful for testing.

## Signals

The tram is dual port, with a system and display port in different clock domains (discussed in more detail below). The signal interfaces is the same as [vram](vram.md) (apart from write-mask granularity).

### Input

* `clk_sys` - system clock
* `clk_pix` - pixel clock (frequency depends on [display](../../gfx/docs/display.md) mode)
* `we_sys` - byte write mask (write-enable)
* `addr_sys` - system port word address
* `din_sys` - system data in
* `addr_disp` - display word address

### Output

* `dout_sys` - system data out
* `dout_disp` - display data out

## Ports

The system (sys) port is for reading and writing characters. The system port is designed for interfacing with a CPU and is in the system clock domain. The display (disp) port is for reading character data for display output and is in the pixel clock domain.

The separate system and displays ports avoid contention between the graphics engine and display logic and form part of the clock-domain crossing (CDC) architecture that allows the system and display clocks to run independently.

### Latencies

* **system port** - 1 cycle read latency
* **display port** - 1 cycle read latency

The display port may have an additional output register added following work on [textmode](../../gfx/docs/textmode.md).
