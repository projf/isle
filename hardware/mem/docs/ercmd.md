# Earthrise Command List

The **ercmd** (Earthrise Command List) module [[verilog src](../ercmd.v)] holds instructions for the [Earthrise](../../gfx/docs/earthrise.md) 2D drawing engine.

The command list uses byte addressing.

## Parameters

* `ADDRW` - address width (bits)
* `BYTE_CNT` - bytes in machine word
* `FILE_INIT` - optional initial command list to load
* `WORD` - machine word size (bits)

For Isle, `BYTE_CNT` must be set to **4** and `WORD` must be set to **32**.

The command list takea a `FILE_INIT` parameter, which allows an initial $readmemh format command list to be loaded at build time.

## Signals

The command list is dual port. The system port is read-write for use of the CPU. Earthrise fetches instructions from a dedicated read-only port. Both ports are in the system domain.

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

* **sys port** - 1 cycle read latency
* **ER port** - 2 cycle read latency

The Earthrise port has a higher latency because of the output register to improve timing.
