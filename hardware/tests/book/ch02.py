# Isle.Computer - Chapter 2 Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Chapter 2 Test Bench (cocotb)"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from tests.helpers import assert_coord, assert_pixel

# clock frequency
SYS_TIME = 50  # 50 ns is 20 MHz

# 640x360 (DISPLAY_MODE=0)
DISP_LINE   = 888  # horizontal line including blanking
DISP_HBLANK = 248  # horizontal blanking
DISP_VBLANK =  15  # vertical blanking


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
async def test_pixel_colour(dut):
    """Test display pixel colour"""
    cocotb.start_soon(Clock(dut.clk, SYS_TIME, unit="ns").start())
    await reset_dut(dut)

    # await start of active pixels
    while not dut.de.value:
        await RisingEdge(dut.clk)
    # await middle of clock before sampling colour
    await Timer(SYS_TIME >> 1, unit='ns')

    # skip to line 4 (passed letterbox)
    await Timer(4*DISP_LINE*SYS_TIME, unit='ns')  # wait the rest of the line

    # pixel line 4
    assert_coord(dut, 0, 4)
    assert_pixel(dut, 14, 8, 17)  # purple
    await Timer(SYS_TIME, unit='ns')
    assert_coord(dut, 1, 4)
    assert_pixel(dut, 12, 19, 31)  # light blue
    await Timer(SYS_TIME, unit='ns')
    assert_coord(dut, 2, 4)
    assert_pixel(dut, 31, 30, 6)  # yellow
    await Timer(SYS_TIME, unit='ns')
    assert_coord(dut, 3, 4)
    assert_pixel(dut, 31, 30, 6)  # yellow
    await Timer((DISP_LINE-3)*SYS_TIME, unit='ns')  # wait the rest of the line

    # pixel line 5
    assert_coord(dut, 0, 5)
    assert_pixel(dut, 12, 19, 31)  # light blue
    await Timer(SYS_TIME, unit='ns')
    assert_coord(dut, 1, 5)
    assert_pixel(dut, 0, 0, 0)  # black
    await Timer((DISP_LINE-1)*SYS_TIME, unit='ns')  # wait the rest of the line

    # pixel line 6
    assert_coord(dut, 0, 6)
    assert_pixel(dut, 31, 30, 6)  # yellow
    await Timer(DISP_LINE*SYS_TIME, unit='ns')  # wait the rest of the line

    # pixel line 7
    assert_coord(dut, 0, 7)
    assert_pixel(dut, 31, 30, 6)  # yellow

    # skip to bottom of display
    await Timer(345*DISP_LINE*SYS_TIME + 639*SYS_TIME, unit='ns')  # 380=377+3 lines from above

    # pixel line 352
    assert_coord(dut, 639, 352)
    assert_pixel(dut, 31, 30, 6)  # yellow
    await Timer(DISP_LINE*SYS_TIME, unit='ns')  # move down one line

    # pixel line 353
    assert_coord(dut, 639, 353)
    assert_pixel(dut, 31, 30, 6)  # yellow
    await Timer(DISP_LINE*SYS_TIME, unit='ns')  # move down one line

    # pixel line 354
    assert_coord(dut, 639, 354)
    assert_pixel(dut, 14, 8, 17)  # purple
    await Timer((DISP_LINE-3)*SYS_TIME, unit='ns')  # move down one line and left 3 pixels

    # pixel line 355
    assert_coord(dut, 636, 355)
    assert_pixel(dut, 31, 30, 6)  # yellow
    await Timer(SYS_TIME, unit='ns')
    assert_coord(dut, 637, 355)
    assert_pixel(dut, 31, 30, 6)  # yellow
    await Timer(SYS_TIME, unit='ns')
    assert_coord(dut, 638, 355)
    assert_pixel(dut, 14, 8, 17)  # purple
    await Timer(SYS_TIME, unit='ns')
    assert_coord(dut, 639, 355)
    assert_pixel(dut, 12, 19, 31)  # light blue

    # wait until line 360 to complete waveform
    await Timer(5*DISP_LINE*SYS_TIME, unit='ns')
