# Synchronous FIFO

The **fifo_sync** [[verilog src](../mem/fifo_sync.v)] module create a synchronous fifo: first in, first out. Isle uses this module to buffer data, for example, keyboard input. A small synchronous fifo is typically implemented in logic, while larger fifos may infer bram.

You can see an example of this module in [uart_dev.v](../devs/uart_dev.v).

## Parameters

* `ADDRW` - address width (bits)
* `DATAW` - data width (bits)

The address width determines the number of items in the fifo. The capacity of the fifo is 2^ADDRW - 1. It's one less because this fifo design uses the final location to distinguish between full and empty.

NB. Reset doesn't clear memory locations; this doesn't affect the operation of the fifo but can be confusing when debugging.

## Signals

### Input

* `clk` - clock
* `rst` - reset
* `we` - write enable
* `re` - read enable
* `din` - data in

### Output

* `dout` - data out
* `len` - length; number of items (occupancy)
* `empty` - fifo empty
* `full` - fifo full
