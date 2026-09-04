# Isle.Computer - Sync FIFO Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Sync FIFO Test Bench (cocotb)"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import NextTimeStep, ReadOnly, RisingEdge

SYS_TIME = 100  # 10 MHz system clock


def gen_test_data(capacity, dataw):
    """Generate fifo test data based on data width and capacity. Never uses 0 as test data."""
    return [i & ((1 << dataw) - 1) for i in range(1, capacity+1)]  # all non-zero


async def setup_dut(dut):
    """Setup DUT with clock and return signal widths."""
    Clock(dut.clk, SYS_TIME, unit="ns").start()
    dut.rst.value = 0
    dut.we.value = 0
    dut.re.value = 0
    dut.din.value = 0
    # reset
    await RisingEdge(dut.clk)
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    capacity = 2**len(dut.len)-1
    return capacity, len(dut.din)


async def write_data(dut, data):
    """Write a list of values on consecutive clocks."""
    for d in data:
        dut.we.value = 1
        dut.din.value = d
        await RisingEdge(dut.clk)  # writes on edge
    dut.we.value = 0
    await RisingEdge(dut.clk)


async def read_data(dut, count, expect_valid=True):
    """Read count values from fifo on consecutive clocks."""
    data_list = []
    dut.re.value = 1
    for i in range(count):
        await RisingEdge(dut.clk)
        await ReadOnly()
        assert dut.dout_valid.value == int(expect_valid), \
            f"dout_valid={int(dut.dout_valid.value)} on read {i}; expected {int(expect_valid)}"
        data_list.append(int(dut.dout.value))
    await NextTimeStep()  # leave read-only state without another clock edge
    dut.re.value = 0  # stop reading
    await RisingEdge(dut.clk)
    await ReadOnly()
    assert dut.dout_valid.value == 0, "dout_valid should be 0 one cycle after re goes low"
    await NextTimeStep()
    return data_list


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_start_empty(dut):
    """Test fifo starts empty."""
    await setup_dut(dut)
    assert dut.empty.value == 1, "fifo didn't start empty."
    assert dut.dout_valid.value == 0, "read didn't start invalid."


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_full_from_empty(dut):
    """Test fifo full from empty."""
    capacity, dataw = await setup_dut(dut)
    test_data_full = gen_test_data(capacity, dataw)  # test data set is as large as the fifo
    await write_data(dut, test_data_full)
    await ReadOnly()
    assert dut.full.value == 1, f"fifo isn't full; len={int(dut.len.value)}."


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_data_and_full(dut):
    """Test fifo data and full after use."""
    capacity, dataw = await setup_dut(dut)

    # write and read a few values (pointers will be non-zero after)
    small_count = capacity // 2
    test_data_small = gen_test_data(small_count, dataw)
    await write_data(dut, test_data_small)
    assert await read_data(dut, small_count) == test_data_small, \
        f"small test read data doesn't match expected {test_data_small}!"

    test_data_full = gen_test_data(capacity, dataw)
    await write_data(dut, test_data_full)

    assert dut.len.value == capacity, \
        f"fifo len={int(dut.len.value)} doesn't match expected {capacity}!"
    assert dut.full.value == 1, f"fifo isn't full; len={int(dut.len.value)}."

    assert await read_data(dut, capacity) == test_data_full, \
        f"test read data doesn't match expected {test_data_full}!"


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_read_simple(dut):
    """Test read of test data."""
    capacity, dataw = await setup_dut(dut)
    test_data_full = gen_test_data(capacity, dataw)
    await write_data(dut, test_data_full)
    assert await read_data(dut, capacity) == test_data_full, \
        f"test read data doesn't match expected {test_data_full}!"
    await ReadOnly()
    assert dut.empty.value == 1, "fifo didn't finish empty."


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_read_when_empty(dut):
    """Test read when fifo empty."""
    capacity, dataw = await setup_dut(dut)
    test_data_full = gen_test_data(capacity, dataw)
    await write_data(dut, test_data_full)
    await read_data(dut, capacity)  # read all data back
    await ReadOnly()
    assert dut.empty.value == 1 and dut.len.value == 0, \
        "read when empty changed pointers"


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_write_when_full(dut):
    """Test write when fifo full."""
    capacity, dataw = await setup_dut(dut)
    test_data_full = gen_test_data(capacity, dataw)
    await write_data(dut, test_data_full)
    sentinel = 0  # gen_test_data never produces 0
    await write_data(dut, [sentinel])  # this value should not be written
    assert dut.len.value == capacity, "fifo len changed on write when full"
    assert await read_data(dut, capacity) == test_data_full, \
        "fifo contents changed on write when full"
    await ReadOnly()
    assert dut.empty.value == 1, "fifo didn't finish empty"
