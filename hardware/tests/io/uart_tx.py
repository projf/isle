# Isle.Computer - UART TX Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""UART TX Test Bench (cocotb)"""

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

test_tx_data = [0x55, 0xA3, 0xFF, 0x00]


async def reset_dut(dut):
    """Reset DUT (single cycle)"""
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    dut.tx_start.value = 0
    dut.din.value = 0
    await RisingEdge(dut.clk)
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)


async def capture_frame(dut):
    """Capture UART frame by sampling mid-bit points."""
    while dut.serial_out.value == 1:
        await RisingEdge(dut.clk)  # wait for start bit

    # check middle of start bit is low
    await ClockCycles(dut.clk, CLOCKS_PER_BIT // 2)
    assert dut.serial_out.value == 0, "Start bit should be low (zero)."

    # sample frame data art mid bit (we're offset to middle from start bit)
    received = 0
    for i in range(UART_DATAW):
        await ClockCycles(dut.clk, CLOCKS_PER_BIT)
        bit = int(dut.serial_out.value)
        received |= (bit << i)

    # check middle of stop bit is high
    await ClockCycles(dut.clk, CLOCKS_PER_BIT)
    assert dut.serial_out.value == 1, "Stop bit should be high (one)."

    return received


@cocotb.test()
async def transmit_data(dut):
    """Test transmitting UART data."""
    cocotb.start_soon(Clock(dut.clk, SYS_TIME, unit="ns").start())

    await reset_dut(dut)

    for data_expected in test_tx_data:
        dut.tx_start.value = 1
        dut.din.value = data_expected
        await RisingEdge(dut.clk)
        dut.tx_start.value = 0

        transmitted = await capture_frame(dut)

        if TEST_INFO:
            cocotb.log.info(f"Transmitted data: 0x{transmitted:02X}")

        assert transmitted == data_expected, \
            f"DUT {transmitted} doesn't match expected {data_expected}!"

        await ClockCycles(dut.clk, CLOCKS_PER_BIT)
