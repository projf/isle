# Synchronous ROM

The sync rom module [[rom_sync.v](../mem/rom_sync.v)] create a synchronous (clocked) rom, typically in block ram. Isle uses small synchronous ROMs for vital data that can't be loaded from external memory, such as the core system font.

## Parameters

* `ADDRW` - address width (bits)
* `DATAW` - data width (bits)
* `DEPTH` - rom depth
* `FILE_ROM` - set rom contents

Because this module creates a rom, you must set `FILE_ROM` to a suitable $readmemh file or the ROM will be empty.

## Signals

### Input

* `clk` - clock
* `addr` - address

### Output

* `dout` - data out
