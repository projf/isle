# UART Receiver

The **uart_rx** [[verilog src](../io/uart_rx.v)] module receives uart data. There is also a uart transmit module [uart_tx.v](uart_tx.md).

Combine with [fifo_sync](../mem/fifo_sync.v) to avoid having to handle every piece of data individually. You can see an example of uart with fifo in [uart_dev.v](../devs/uart_dev.v), which wraps the UART for MMIO from the CPU.

## Parameters

* `UART_CNT_INC` - 16 x baud counter increment
* `UART_CNT_W` - 16 x baud counter width (bits)
* `UART_DATAW` - UART data width (bits)

The module defaults to 115200 baud with 20 MHz system clock.

## Signals

### Input

* `clk` - clock
* `rst` - reset
* `serial_in` - serial data in

### Output

* `dout` - data received
* `rx_busy` - busy receiving
* `rx_done` - receive complete

`rx_done` is only high for one clock cycle.

## Testing

There is a cocotb test bench [[python src](../tests/io/uart_rx.py)] that exercises this module. For advice on running hardware tests, see [Isle Verilog Tests](../tests/README.md).
