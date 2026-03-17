# Isle.Computer - UART RX Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""UART RX Test Bench (cocotb)"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

TEST_INFO = 1  # display test data

# clock frequencies
SYS_TIME = 50  # 50 ns is 20 MHz

# uart parameters - must match Verilog params
UART_CNT_W = 16
UART_CNT_INC = 503
UART_DATAW = 8

CLOCKS_PER_BIT = int(((2 ** UART_CNT_W) / UART_CNT_INC) * 16)

test_rx_data = [0x55, 0xA3, 0xFF, 0x00]


async def reset_dut(dut):
    """Reset DUT (single cycle)"""
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    dut.serial_in.value = 1  # serial is high when idle
    await RisingEdge(dut.clk)
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)


async def send_frame(dut, data_val):
    """Send UART frame (start bit, data bits, stop bit)."""
    dut.serial_in.value = 0  # go low to signal start
    await ClockCycles(dut.clk, CLOCKS_PER_BIT)

    for i in range(UART_DATAW):
        dut.serial_in.value = (data_val >> i) & 1
        await ClockCycles(dut.clk, CLOCKS_PER_BIT)

    dut.serial_in.value = 1  # go high to signal stop
    await ClockCycles(dut.clk, CLOCKS_PER_BIT)


@cocotb.test()
async def receive_data(dut):
    """Test receiving UART data."""
    cocotb.start_soon(Clock(dut.clk, SYS_TIME, unit="ns").start())

    await reset_dut(dut)

    for data_expected in test_rx_data:
        await send_frame(dut, data_expected)

        while not dut.rx_done.value:
            await RisingEdge(dut.clk)

        if dut.dout.value.is_resolvable:
            received = dut.dout.value.to_unsigned()
        else:
            received = dut.dout.value

        if TEST_INFO:
            cocotb.log.info(f"Received data: 0x{received:02X}")

        assert received == data_expected, \
            f"DUT {received} doesn't match expected {data_expected}!"

        await ClockCycles(dut.clk, CLOCKS_PER_BIT)
