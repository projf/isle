# Synchronous FIFO

The sync fifo module [[fifo_sync.v](../mem/fifo_sync.v)] creates a synchronous fifo (first in, first out - AKA queue). Isle uses this module to buffer data, for example, keyboard input. A small synchronous fifo is typically implemented in logic, while larger fifos may infer bram.

## Use

### Reading

Reads when `empty` return undefined data.

To read, ensure the fifo isn't `empty`, set `re` high then wait one cycle before reading from `dout`. You can also check `dout_valid` before using `dout`; it's only high when `re` and `empty` are valid for reading.

### Writing

Writes when `full` are silently ignored.

To write, ensure the fifo isn't `full`, put your data in `din` and set `we` high.

### Reset

Resetting the FIFO sets both read and write pointers to zero. Reset doesn't clear memory locations; this doesn't affect the operation of the fifo but can be confusing when debugging.

## Parameters

* `ADDRW` - address width (bits)
* `DATAW` - data width (bits)

The address width determines the number of items in the fifo. The capacity of the fifo is 2^ADDRW - 1. It's one less because this fifo design uses one location to distinguish between full and empty. For example, if ADDRW = 4, then the fifo holds 15 items.

## Signals

### Input

* `clk` - clock
* `rst` - reset
* `we` - write enable
* `re` - read enable
* `din` - data in

### Output

* `dout` - data out
* `dout_valid` - high for valid reads
* `len` - length; number of items (occupancy)
* `empty` - fifo empty
* `full` - fifo full

## Testing

There is a cocotb test bench [[fifo_sync.py](../tests/mem/fifo_sync.py)] that exercises this module. For advice on running hardware tests, see [Isle Verilog Tests](../tests/README.md).
