# Isle.Computer - Chapter 2 Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Chapter 2 Test Bench (cocotb)"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from tests.helpers import assert_coord, assert_pixel

# clock frequency
SYS_TIME = 40  # 40 ns is 25 MHz

# 672x384 (DISPLAY_MODE=3)
DISP_LINE   = 800  # horizontal line including blanking
DISP_HBLANK = 128  # horizontal blanking
DISP_VBLANK = 137  # vertical blanking


async def reset_dut(dut):
    """Reset DUT (single cycle)"""
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def pixel_colour(dut):
    """Test display pixel colour"""
    cocotb.start_soon(Clock(dut.clk, SYS_TIME, units="ns").start())
    await reset_dut(dut)

    # await start of active pixels
    while not dut.de.value:
        await RisingEdge(dut.clk)
    # await middle of clock before sampling colour
    await Timer(SYS_TIME >> 1, units='ns')

    # pixel line 0
    assert_coord(dut, 0, 0)
    assert_pixel(dut, 14, 8, 17)  # purple
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 1, 0)
    assert_pixel(dut, 12, 19, 31)  # light blue
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 2, 0)
    assert_pixel(dut, 31, 30, 6)  # yellow
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 3, 0)
    assert_pixel(dut, 31, 30, 6)  # yellow
    await Timer((DISP_LINE-3)*SYS_TIME, units='ns')  # wait the rest of the line

    # pixel line 1
    assert_coord(dut, 0, 1)
    assert_pixel(dut, 12, 19, 31)  # light blue
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 1, 1)
    assert_pixel(dut, 0, 0, 0)  # black
    await Timer((DISP_LINE-1)*SYS_TIME, units='ns')  # wait the rest of the line

    # pixel line 2
    assert_coord(dut, 0, 2)
    assert_pixel(dut, 31, 30, 6)  # yellow
    await Timer(DISP_LINE*SYS_TIME, units='ns')  # wait the rest of the line

    # pixel line 3
    assert_coord(dut, 0, 3)
    assert_pixel(dut, 31, 30, 6)  # yellow

    # skip to bottom of display
    await Timer(377*DISP_LINE*SYS_TIME + 671*SYS_TIME, units='ns')  # 380=377+3 lines from above

    # pixel line 380
    assert_coord(dut, 671, 380)
    assert_pixel(dut, 31, 30, 6)  # yellow
    await Timer(DISP_LINE*SYS_TIME, units='ns')  # move down one line

    # pixel line 381
    assert_coord(dut, 671, 381)
    assert_pixel(dut, 31, 30, 6)  # yellow
    await Timer(DISP_LINE*SYS_TIME, units='ns')  # move down one line

    # pixel line 382
    assert_coord(dut, 671, 382)
    assert_pixel(dut, 14, 8, 17)  # purple
    await Timer((DISP_LINE-3)*SYS_TIME, units='ns')  # move down one line and left 3 pixels

    # pixel line 383
    assert_coord(dut, 668, 383)
    assert_pixel(dut, 31, 30, 6)  # yellow
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 669, 383)
    assert_pixel(dut, 31, 30, 6)  # yellow
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 670, 383)
    assert_pixel(dut, 14, 8, 17)  # purple
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 671, 383)
    assert_pixel(dut, 12, 19, 31)  # light blue

    # wait one more line to complete waveform
    await Timer(DISP_LINE*SYS_TIME, units='ns')
