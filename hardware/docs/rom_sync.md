# Synchronous Rom

The [[rom_sync.v](../mem/rom_sync.v)] module creates a synchronous (clocked) rom. Isle uses small synchronous roms for vital data that can't be loaded from external memory, such as the core system font. Depending on your FPGA and toolchain, it may be implemented in logic (luts) or block ram (bram).

## Parameters

* `ADDRW` - address width (bits)
* `DATAW` - data width (bits)
* `DEPTH` - rom depth
* `FILE_ROM` - rom contents file ($readmemh format)

Because this module creates a rom, you must set `FILE_ROM` to a suitable $readmemh file or the rom will have undefined contents.

`DEPTH` can be set directly, but must be at most `2**ADDRW`; this is different from most Isle memories, where depth is derived from the address width. The freedom to control the depth allows small roms (e.g. with 12 entries) to use less logic. Reading an address at or beyond `DEPTH` returns undefined data.

## Signals

### Input

* `clk` - clock
* `addr` - address

### Output

* `dout` - data out

## Latency

This design is synchronous with 1 cycle of latency. After `addr` is set, the data at that address is available on `dout` after the next rising edge of the clock.

## Testing

There is a cocotb test bench [[rom_sync.py](../tests/mem/rom_sync.py)] that exercises this module. For advice on running hardware tests, see [Isle Verilog Tests](../tests/README.md).

