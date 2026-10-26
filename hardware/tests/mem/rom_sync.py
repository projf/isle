# Isle.Computer - Synchronous Rom Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Synchronous Rom Test Bench (cocotb)

Reads every rom address in a random order. The rom is populated with an init
file that's also read by the test bench. Inputs change and outputs are read on
the falling edge of the clock.
"""

import os
import random

import cocotb
from cocotb.clock import Clock
from tests.helpers import read_hex_file, read_mem

SYS_TIME = 100  # 100 ns is 10 MHz

# read latency (clock cycles) - documented in rom_sync.md
SYS_LAT = 1


def start_rom_sync(dut):
    """Start clock."""
    cocotb.start_soon(Clock(dut.clk, SYS_TIME, unit="ns").start())


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_rom_read(dut):
    """Test rom data read."""
    start_rom_sync(dut)
    rom_data = read_hex_file(os.environ["INIT_FILE"])  # makefile sets INIT_FILE
    addr_list = list(range(len(rom_data)))
    random.shuffle(addr_list)
    expected = [rom_data[addr] for addr in addr_list]

    reads = await read_mem(dut.clk, dut.addr, dut.dout, addr_list, SYS_LAT)
    assert reads == expected
