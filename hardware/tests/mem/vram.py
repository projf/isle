# Isle.Computer - Vram Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Vram Test Bench (cocotb)

Tests write random data using the system port, read it back from the system and
display ports. Input signals change on the falling edge, and output signals are
checked on the falling edge. Includes test of 32-bit write mask.

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

# read latencies (clock cycles) - documented in vram.md
SYS_LAT = 1
DISP_LAT = 2


def start_vram(dut):
    """Start clocks and idle system port."""
    cocotb.start_soon(Clock(dut.clk_sys, SYS_TIME, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_pix, PIX_TIME, unit="ns").start())
    dut.wmask_sys.value = 0
    dut.re_sys.value = 0


async def write_vram(dut, model, mask):
    """Write model {addr: data} to vram via system port using mask."""
    await FallingEdge(dut.clk_sys)
    dut.wmask_sys.value = mask
    for addr, din in model.items():
        dut.addr_sys.value = addr
        dut.din_sys.value = din
        await FallingEdge(dut.clk_sys)
    dut.wmask_sys.value = 0


def masked_write(old, din, mask):
    """Apply a bit write mask in the same way as vram hardware. See vram.md."""
    return (old & ~mask) | (din & mask)


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_sys_port(dut):
    """Test vram system port read and write."""
    start_vram(dut)
    model = random_mem_model(len(dut.addr_sys), len(dut.din_sys))
    word_mask = (1 << len(dut.din_sys)) - 1
    await write_vram(dut, model, word_mask)

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
    """Test vram disp port read (no write on disp port)."""
    start_vram(dut)
    model = random_mem_model(len(dut.addr_sys), len(dut.din_sys))
    word_mask = (1 << len(dut.din_sys)) - 1
    await write_vram(dut, model, word_mask)  # write test data via system port

    addr_list = list(model.keys())
    random.shuffle(addr_list)
    expected = [model[addr] for addr in addr_list]

    reads = await read_mem(dut.clk_pix, dut.addr_disp, dut.dout_disp,
        addr_list, DISP_LAT)
    assert reads == expected


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_wmask(dut):
    """Test vram system port bit write mask."""
    start_vram(dut)
    masks = [
        0x00000000, 0xFFFFFFFF,  # 0 and full mask
        0x00000001, 0x80000000,  # 1 bit
        0x00000030, 0x0C000000,  # 2 bit
        0x00000F00, 0x00F00000,  # 4 bit
        0x0000FF00, 0x00FF0000,  # 8 bit (byte)
        0x0000FFFF, 0xFFFF0000,  # 16 bit (half word)
        0xAAAAAAAA, 0x55555555   # alternate bits
    ]
    assert len(dut.din_sys) == 32, "test_wmask requires 32-bit din_sys."

    model = random_mem_model(len(dut.addr_sys), len(dut.din_sys))

    addr_list = list(model.keys())[:len(masks)]  # match mask length
    assert len(addr_list) == len(masks), "ADDRW too small for test."

    word_mask = (1 << len(dut.din_sys)) - 1

    # write known model with all mask bits enabled
    original_data = {addr: model[addr] for addr in addr_list}
    await write_vram(dut, original_data, word_mask)

    # invert every bit in original_data, so a write to any bit is detected
    new_data = {addr: ~original_data[addr] & word_mask for addr in addr_list}

    # write with mask
    await FallingEdge(dut.clk_sys)
    for addr, mask in zip(addr_list, masks):
        dut.wmask_sys.value = mask
        dut.addr_sys.value = addr
        dut.din_sys.value = new_data[addr]
        await FallingEdge(dut.clk_sys)
    dut.wmask_sys.value = 0

    expected = [masked_write(original_data[addr], new_data[addr], mask)
        for addr, mask in zip(addr_list, masks)]

    dut.re_sys.value = 1
    reads = await read_mem(dut.clk_sys, dut.addr_sys, dut.dout_sys,
        addr_list, SYS_LAT)
    assert reads == expected
    dut.re_sys.value = 0
