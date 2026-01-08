# Earthrise System Memory

The **sysram** module [[verilog src](../mem/sysram.v)] is Isle's main memory in block ram (bram). The sysram has a 32-bit data bus and uses byte addressing.

## Parameters

* `ADDRW` - address width (bits)
* `BYTE` - machine byte size (bits)
* `BYTE_CNT` - bytes in machine word
* `WORD` - machine word size (bits)
* `FILE_SOFT` - optional initial software to load

For Isle, `BYTE` must be set to **8**, `BYTE_CNT` must be set to **4**, and `WORD` must be set to **32**.

The command list takes a `FILE_SOFT` parameter, which allows initial $readmemh format [software](../../software/) to be loaded at build time.

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
