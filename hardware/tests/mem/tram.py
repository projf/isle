# Isle.Computer - Tram Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Tram Test Bench (cocotb)

Tests write random data using the system port, read it back from the system and
display ports. Input signals change on the falling edge, and output signals are
checked on the falling edge. Includes test of byte write.

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

# read latencies (clock cycles) - documented in tram.md
SYS_LAT = 1
DISP_LAT = 2


def start_tram(dut):
    """Start clocks and idle system port."""
    cocotb.start_soon(Clock(dut.clk_sys, SYS_TIME, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_pix, PIX_TIME, unit="ns").start())
    dut.we_sys.value = 0
    dut.re_sys.value = 0


async def write_tram(dut, model, we_sys):
    """Write model {addr: data} to tram via system port."""
    await FallingEdge(dut.clk_sys)
    dut.we_sys.value = we_sys  # byte writable
    for addr, din in model.items():
        dut.addr_sys.value = addr
        dut.din_sys.value = din
        await FallingEdge(dut.clk_sys)
    dut.we_sys.value = 0


def masked_write(old, din, byte_mask):
    """Apply a byte write mask in the same way as tram hardware."""
    bit_mask = 0
    for i in range(4):
        if byte_mask & (1 << i):
            bit_mask |= 0xFF << (8 * i)
    return (old & ~bit_mask) | (din & bit_mask)


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_sys_port(dut):
    """Test tram system port read and write."""
    start_tram(dut)
    model = random_mem_model(len(dut.addr_sys), len(dut.din_sys))
    we_sys = 0b1111  # write whole words (4 bytes)
    await write_tram(dut, model, we_sys)

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
    """Test tram disp port read (no write on disp port)."""
    start_tram(dut)
    model = random_mem_model(len(dut.addr_sys), len(dut.din_sys))
    we_sys = 0b1111  # write whole words (4 bytes)
    await write_tram(dut, model, we_sys)  # write test data via system port

    addr_list = list(model.keys())
    random.shuffle(addr_list)
    expected = [model[addr] for addr in addr_list]

    reads = await read_mem(dut.clk_pix, dut.addr_disp, dut.dout_disp,
        addr_list, DISP_LAT)
    assert reads == expected


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_byte_write(dut):
    """Test tram system port byte write mask."""
    start_tram(dut)
    byte_masks = [  # includes all valid CPU combinations
        0b0000, 0b1111,  # 0 bytes and 4 bytes (word)
        0b0001, 0b0010,  # 1 byte (1st and second byte)
        0b0100, 0b1000,  # 1 byte (3rd and fourth byte)
        0b0011, 0b1100   # 2 bytes (half words)
    ]
    assert len(dut.din_sys) == 32, "test_byte_write requires 32-bit din_sys."

    model = random_mem_model(len(dut.addr_sys), len(dut.din_sys))

    addr_list = list(model.keys())[:len(byte_masks)]  # match mask length
    assert len(addr_list) == len(byte_masks), "ADDRW too small for test."

    we_sys = 0b1111  # write whole words (4 bytes)

    # write known model with all mask bits enabled
    original_data = {addr: model[addr] for addr in addr_list}
    await write_tram(dut, original_data, we_sys)

    # invert every bit in original_data, so a write to any byte is detected
    word_mask = (1 << len(dut.din_sys)) - 1
    new_data = {addr: ~original_data[addr] & word_mask for addr in addr_list}

    # write with mask
    await FallingEdge(dut.clk_sys)
    for addr, mask in zip(addr_list, byte_masks):
        dut.we_sys.value = mask
        dut.addr_sys.value = addr
        dut.din_sys.value = new_data[addr]
        await FallingEdge(dut.clk_sys)
    dut.we_sys.value = 0

    expected = [masked_write(original_data[addr], new_data[addr], mask)
        for addr, mask in zip(addr_list, byte_masks)]

    dut.re_sys.value = 1
    reads = await read_mem(dut.clk_sys, dut.addr_sys, dut.dout_sys,
        addr_list, SYS_LAT)
    assert reads == expected
    dut.re_sys.value = 0
