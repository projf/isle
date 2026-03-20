# UART Transmitter

The **uart_tx** [[verilog src](../io/uart_tx.v)] module transmits uart data. There is also a uart receive module [uart_rx.v](uart_rx.md).

As of March 2026, `uart_tx` is not yet used in Isle. The Verilator/SDL simulator uses a similar design to `uart_tx` to send keyboard input to Isle when running in simulation; see [sdl_sim.h](../../boards/verilator/sdl_sim.h).

## Parameters

* `UART_CNT_INC` - 16 x baud counter increment
* `UART_CNT_W` - 16 x baud counter width (bits)
* `UART_DATAW` - UART data width (bits)

The module defaults to 115200 baud with 20 MHz system clock.

## Signals

### Input

* `clk` - clock
* `rst` - reset
* `tx_start` - start transmission
* `din` - data in

### Output

* `serial_out` - serial data out
* `tx_busy` - busy transmitting
* `tx_done` - transmit complete

`tx_done` is only high for one clock cycle.

## Testing

There is a cocotb test bench [[python src](../tests/io/uart_tx.py)] that exercises this module. For advice on running hardware tests, see [Isle Verilog Tests](../tests/README.md).
