# System Memory

The **sysram** module [[verilog src](../mem/sysram.v)] is Isle's main memory in block ram (bram). The sysram has a 32-bit data bus and uses **word addressing** but with byte write support.

## Parameters

* `ADDRW` - address width (bits)
* `BYTE` - machine byte size (bits)
* `BYTE_CNT` - bytes in machine word
* `WORD` - machine word size (bits)
* `FILE_SOFT` - optional initial software to load

The command list takes a `FILE_SOFT` parameter, which allows initial $readmemh format [software](../../software/) to be loaded at build time.

The depth (size) of sysram is derived from the address width `ADDRW`. The address width is in words, not bytes; for example, an address width of 12 creates a 16 KiB memory.

## Signals

### Input

* `clk` - clock
* `we` - write enable (byte mask)
* `re` - read enable
* `addr` - address
* `din` - data in

### Output

* `dout` - data out

## Latencies

Reads have a 1 cycle read latency.
