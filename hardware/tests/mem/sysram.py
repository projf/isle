# Isle.Computer - System Ram Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""System Ram Test Bench (cocotb)

Tests write random data and read it back. Input signals change on the falling
edge, and output signals are checked on the falling edge.

This memory does not have a reset, so tests cannot make any assumptions about
the memory contents. Each test writes to every address it reads.
"""

import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from tests.helpers import random_mem_model, read_mem

# clock frequency
SYS_TIME = 50  # 50 ns is 20 MHz

# read latency (clock cycles) - documented in sysram.md
SYS_LAT = 1


def start_sysram(dut):
    """Start clock and idle inputs."""
    cocotb.start_soon(Clock(dut.clk, SYS_TIME, unit="ns").start())
    dut.we.value = 0
    dut.re.value = 0


async def write_sysram(dut, model, byte_mask):
    """Write model {addr: data} to sysram via system port."""
    await FallingEdge(dut.clk)
    dut.we.value = byte_mask  # byte writable
    for addr, din in model.items():
        dut.addr.value = addr
        dut.din.value = din
        await FallingEdge(dut.clk)
    dut.we.value = 0


def masked_write(old, din, byte_mask):
    """Apply a byte write mask in the same way as sysram hardware."""
    bit_mask = 0
    for i in range(4):
        if byte_mask & (1 << i):
            bit_mask |= 0xFF << (8 * i)
    return (old & ~bit_mask) | (din & bit_mask)


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_sys_port(dut):
    """Test sysram system port read and write."""
    start_sysram(dut)
    model = random_mem_model(len(dut.addr), len(dut.din))
    all_bytes = (1 << len(dut.we)) - 1
    await write_sysram(dut, model, all_bytes)

    addr_list = list(model.keys())  # addresses in order they were written
    random.shuffle(addr_list)  # shuffle so we read in a different order
    expected = [model[addr] for addr in addr_list]

    dut.re.value = 1
    for _ in range(2):  # check twice to ensure reading didn't change data
        reads = await read_mem(dut.clk, dut.addr, dut.dout,
            addr_list, SYS_LAT)
        assert reads == expected
    dut.re.value = 0


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_byte_write(dut):
    """Test sysram system port byte write mask."""
    start_sysram(dut)
    byte_masks = list(range(16))  # test all possible combinations
    assert len(dut.din) == 32, "test_byte_write requires 32-bit din."

    model = random_mem_model(len(dut.addr), len(dut.din))

    addr_list = list(model.keys())[:len(byte_masks)]  # match mask length
    assert len(addr_list) == len(byte_masks), "ADDRW too small for test."

    we = 0b1111  # write whole words (4 bytes)

    # write known model with all mask bits enabled
    original_data = {addr: model[addr] for addr in addr_list}
    await write_sysram(dut, original_data, we)

    # invert every bit in original_data, so a write to any byte is detected
    word_mask = (1 << len(dut.din)) - 1
    new_data = {addr: ~original_data[addr] & word_mask for addr in addr_list}

    # write with mask
    await FallingEdge(dut.clk)
    for addr, mask in zip(addr_list, byte_masks):
        dut.we.value = mask
        dut.addr.value = addr
        dut.din.value = new_data[addr]
        await FallingEdge(dut.clk)
    dut.we.value = 0

    expected = [masked_write(original_data[addr], new_data[addr], mask)
        for addr, mask in zip(addr_list, byte_masks)]

    dut.re.value = 1
    reads = await read_mem(dut.clk, dut.addr, dut.dout,
        addr_list, SYS_LAT)
    assert reads == expected
    dut.re.value = 0
