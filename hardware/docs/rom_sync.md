# Synchronous ROM

The **rom_sync** [[verilog src](../mem/rom_sync.v)] module create a synchronous ROM, typically in block ram. Isle uses small synchronous ROMs for vital data, such as the core system font.

## Parameters

* `ADDRW` - address width (bits)
* `DATAW` - data width (bits)
* `DEPTH` - ROM depth
* `FILE_ROM` - set ROM contents

Because this module creates a ROM, you must set `FILE_ROM` to a suitable $readmemh file or the ROM will be empty.

## Signals

### Input

* `clk` - clock
* `addr` - address

### Output

* `dout` - data out
