# Isle.Computer - Synchronous Rom Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Synchronous Rom Test Bench (cocotb)"""

import os
import random

import cocotb
from cocotb.clock import Clock
from tests.helpers import read_mem

SYS_TIME = 100  # 10 MHz system clock

# read latency (clock cycles) - documented in rom_sync.md
SYS_LAT = 1


def start_rom_sync(dut):
    """Start clock."""
    cocotb.start_soon(Clock(dut.clk, SYS_TIME, unit="ns").start())


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_rom_read(dut):
    """Test ROM data read."""

    start_rom_sync(dut)

    # setup test data
    init_file = os.environ["INIT_FILE"]  # makefile adds filename to env

    rom_data = []
    with open(init_file, 'r', encoding='utf8') as f:
        for li in f:
            li = li.strip()
            if li and not li.startswith("//"):
                rom_data.append(int(li, base=16))

    addr_list = list(range(len(rom_data)))
    random.shuffle(addr_list)
    expected = [rom_data[addr] for addr in addr_list]

    reads = await read_mem(dut.clk, dut.addr, dut.dout, addr_list, SYS_LAT)
    assert reads == expected
