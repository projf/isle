# Isle.Computer - Chapter 1 Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Chapter 1 Test Bench (cocotb)"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from tests.helpers import assert_coord, assert_pixel

# clock frequency
SYS_TIME = 40  # 40 ns is 25 MHz

# 640x480 (DISPLAY_MODE=0)
DISP_LINE   = 800  # horizontal line including blanking
DISP_HBLANK = 160  # horizontal blanking
DISP_VBLANK =  45  # vertical blanking


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
    assert_pixel(dut, 2, 6, 14)  # dark blue
    await Timer(DISP_LINE*SYS_TIME, units='ns')  # wait the rest of the line

    # skip to line 140
    await Timer(139*DISP_LINE*SYS_TIME + 219*SYS_TIME, units='ns')

    # pixel line 140
    assert_coord(dut, 219, 140)
    assert_pixel(dut, 2, 6, 14)  # dark blue
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 220, 140)
    assert_pixel(dut, 31, 31, 31)  # white
    await Timer((DISP_LINE-220)*SYS_TIME, units='ns')  # wait the rest of the line

    # skip to line 339
    await Timer(198*DISP_LINE*SYS_TIME + 419*SYS_TIME, units='ns')

    # pixel line 339
    assert_coord(dut, 419, 339)
    assert_pixel(dut, 31, 31, 31)  # white
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 420, 339)
    assert_pixel(dut, 2, 6, 14)  # dark blue
    await Timer((DISP_LINE-420)*SYS_TIME, units='ns')  # wait the rest of the line

    # skip to bottom of display
    await Timer(139*DISP_LINE*SYS_TIME + 639*SYS_TIME, units='ns')

    # pixel line 479
    assert_coord(dut, 639, 479)
    assert_pixel(dut, 2, 6, 14)  # dark blue

    # wait one more line to complete waveform
    await Timer(DISP_LINE*SYS_TIME, units='ns')
