# Isle.Computer - Synchronous Fifo Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Synchronous Fifo Test Bench (cocotb)
Tests write random data and read it back. Input signals change on the falling
edge, and output signals are checked on the falling edge.

The fifo must be reset prior to use (this is different from other memories).
"""

import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge

# clock frequency
SYS_TIME = 100  # 100 ns is 10 MHz


def start_fifo(dut):
    """Start clock and idle inputs."""
    cocotb.start_soon(Clock(dut.clk, SYS_TIME, unit="ns").start())
    dut.we.value = 0
    dut.re.value = 0
    dut.din.value = 0


async def reset_fifo(dut):
    """Reset fifo."""
    await FallingEdge(dut.clk)
    dut.rst.value = 1
    await FallingEdge(dut.clk)
    dut.rst.value = 0


def fifo_capacity(dut):
    """Return capacity (one less than depth)."""
    return 2**len(dut.len) - 1


def random_fifo_data(dut, count):
    """Generate count random, distinct non-zero values that fit in din."""
    return random.sample(range(1, 2**len(dut.din)), count)


async def write_fifo(dut, data):
    """Write a list of values on consecutive clocks."""
    await FallingEdge(dut.clk)
    dut.we.value = 1
    for d in data:
        dut.din.value = d
        await FallingEdge(dut.clk)
    dut.we.value = 0


async def read_fifo(dut, count):
    """Read count values from fifo on consecutive clocks."""
    await FallingEdge(dut.clk)
    reads = []
    dut.re.value = 1
    for _ in range(count):
        await FallingEdge(dut.clk)
        if dut.dout_valid.value == 1:
            reads.append(dut.dout.value.to_unsigned())
    dut.re.value = 0
    return reads


async def write_read_fifo(dut, data):
    """Simultaneous write and read fifo on consecutive clocks. Return reads."""
    await FallingEdge(dut.clk)
    reads = []
    dut.we.value = 1
    dut.re.value = 1
    for d in data:
        dut.din.value = d
        await FallingEdge(dut.clk)
        if dut.dout_valid.value == 1:
            reads.append(dut.dout.value.to_unsigned())
    dut.we.value = 0
    dut.re.value = 0
    return reads


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_reset(dut):
    """Test fifo reset."""
    start_fifo(dut)
    await reset_fifo(dut)

    assert dut.empty.value == 1
    assert dut.full.value == 0
    assert dut.len.value == 0
    assert dut.dout_valid.value == 0


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_fill_drain(dut):
    """Test filling and draining fifo."""
    start_fifo(dut)
    await reset_fifo(dut)

    capacity = fifo_capacity(dut)
    test_data = random_fifo_data(dut, capacity)
    await write_fifo(dut, test_data)

    assert dut.empty.value == 0
    assert dut.full.value == 1
    assert dut.len.value == capacity

    reads = await read_fifo(dut, capacity)
    assert reads == test_data

    assert dut.empty.value == 1
    assert dut.full.value == 0
    assert dut.len.value == 0

    await FallingEdge(dut.clk)  # dout_valid matches dout; lags re by one cycle
    assert dut.dout_valid.value == 0


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_pointer_wrap(dut):
    """Test pointers wrap correctly."""
    start_fifo(dut)
    await reset_fifo(dut)

    capacity = fifo_capacity(dut)

    # write and read half the capacity
    half_capacity = capacity // 2
    half_test_data = random_fifo_data(dut, half_capacity)
    await write_fifo(dut, half_test_data)
    half_reads = await read_fifo(dut, half_capacity)
    assert half_reads == half_test_data

    # write and read whole capacity so pointers wrap
    test_data = random_fifo_data(dut, capacity)
    await write_fifo(dut, test_data)
    reads = await read_fifo(dut, capacity)
    assert reads == test_data


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_read_empty(dut):
    """Test reading empty fifo."""
    start_fifo(dut)
    await reset_fifo(dut)

    count = 3
    test_data = random_fifo_data(dut, count)
    await write_fifo(dut, test_data)
    reads = await read_fifo(dut, count+2)  # try reading another two items
    assert reads == test_data  # extra reads return nothing
    assert dut.empty.value == 1
    assert dut.len.value == 0


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_write_when_full(dut):
    """Test writing to full fifo."""
    start_fifo(dut)
    await reset_fifo(dut)

    capacity = fifo_capacity(dut)
    test_data = random_fifo_data(dut, capacity)
    await write_fifo(dut, test_data)

    sentinel = 0  # random_fifo_data never produces 0
    await write_fifo(dut, [sentinel])  # this value should not be written
    assert dut.len.value == capacity
    reads = await read_fifo(dut, capacity)
    assert reads == test_data


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_read_while_write(dut):
    """Test writing and reading simultaneously."""
    start_fifo(dut)
    await reset_fifo(dut)

    capacity = fifo_capacity(dut)
    test_data = random_fifo_data(dut, capacity)
    reads = await write_read_fifo(dut, test_data)  # first read from empty fifo
    assert reads == test_data[:-1]  # ...so compare with all but last test item
    assert dut.len.value == 1  # check last write still in fifo
    last_read = await read_fifo(dut, 1)
    assert last_read == test_data[-1:]  # check last read matches last test item
