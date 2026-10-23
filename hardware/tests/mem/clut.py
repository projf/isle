# Isle.Computer - Clut Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Clut Test Bench (cocotb)

Tests write random data using the system port, read it back from the system and
display ports. Input signals change on the falling edge, and output signals are
checked on the falling edge.

This memory does not have a reset, so tests cannot make any assumptions about
the memory contents. Each test writes to every address it reads.
"""

import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from tests.helpers import random_mem_model, read_mem

# clock frequencies
SYS_TIME = 50  # 50 ns is 20 MHz
PIX_TIME = 20  # 20 ns is 50 MHz

# read latencies (clock cycles) - documented in clut.md
SYS_LAT = 1
DISP_LAT = 2


def start_clut(dut):
    """Start clocks and idle system port."""
    cocotb.start_soon(Clock(dut.clk_sys, SYS_TIME, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_pix, PIX_TIME, unit="ns").start())
    dut.we_sys.value = 0
    dut.re_sys.value = 0


async def write_clut(dut, model):
    """Write model {addr: data} to clut via system port."""
    await FallingEdge(dut.clk_sys)
    dut.we_sys.value = 1
    for addr, din in model.items():
        dut.addr_sys.value = addr
        dut.din_sys.value = din
        await FallingEdge(dut.clk_sys)
    dut.we_sys.value = 0


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_sys_port(dut):
    """Test clut system port read and write."""
    start_clut(dut)
    model = random_mem_model(len(dut.addr_sys), len(dut.din_sys))
    await write_clut(dut, model)

    addr_list = list(model.keys())  # addresses in order they were written
    random.shuffle(addr_list)  # shuffle so we read in a different order
    expected = [model[addr] for addr in addr_list]

    dut.re_sys.value = 1
    for _ in range(2):  # check twice to ensure reading didn't change data
        reads = await read_mem(dut.clk_sys, dut.addr_sys, dut.dout_sys,
            addr_list, SYS_LAT)
        assert reads == expected
    dut.re_sys.value = 0


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_disp_port(dut):
    """Test clut disp port read (no write on disp port)."""
    start_clut(dut)
    model = random_mem_model(len(dut.addr_sys), len(dut.din_sys))
    await write_clut(dut, model)  # write test data via system port

    addr_list = list(model.keys())
    random.shuffle(addr_list)
    expected = [model[addr] for addr in addr_list]

    reads = await read_mem(dut.clk_pix, dut.addr_disp, dut.dout_disp,
        addr_list, DISP_LAT)
    assert reads == expected
