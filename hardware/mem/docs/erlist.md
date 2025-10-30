# Earthrise Command List

The **erlist** (Earthrise Command List) module [[verilog src](../erlist.v)] holds instructions for the [Earthrise](../../gfx/docs/earthrise.md) 2D drawing engine.

## Parameters

* `ADDRW` - address width (bits)
* `BYTE_CNT` - bytes in machine word
* `FILE_INIT` - optional initial command list to load
* `WORD` - machine word size (bits)

For Isle, `BYTE_CNT` must be set to **4** and `WORD` must be set to **32**.

The command list takea a `FILE_INIT` parameter, which allows an initial $readmemh format command list to be loaded at build time. Use the Earthrise assembler, [erasm](../../../tools/erasm/), to generate a suitable file.

## Signals

The command list is dual port. The system port is read-write for use of the CPU. Earthrise fetches instructions from a dedicated read-only port. Both ports are in the system domain. The command list has a 32-bit data bus and uses byte addressing. Earthrise instructions are 16-bit, so two instructions are packed (little endian) into each memory location.

### Input

* `clk` - clock
* `we_sys` - system write enable
* `addr_sys` - system address
* `din_sys` - system data in
* `addr_er` - Earthrise address

### Output

* `dout_sys` - system data out
* `dout_er` - Earthrise data out

## Latencies

* **system port** - 1 cycle read latency
* **Earthrise port** - 2 cycle read latency

The Earthrise port has a higher latency because of the output register to improve timing.
