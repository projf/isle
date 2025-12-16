# Isle.Computer - Chapter 2 Test Bench
# Copyright Will Green

"""Chapter 2 Test Bench (cocotb)"""

import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer

TEST_INFO   =   1  # display test info (colour and coordinate) for passing tests
SYS_TIME    =  40  # 25 MHz - clock frequency

# 672x384 (DISPLAY_MODE=3)
DISP_LINE   = 800  # 800 pixels in line including blanking
DISP_HBLANK = 128  # 128 pixels in horizontal blanking
DISP_VBLANK = 137  # 137 lines in vertical blanking


def assert_pixel(dut, r, g, b):
    """Assert pixel colour is correct"""
    if (TEST_INFO): log_pixel(dut)
    assert dut.disp_r.value == r and dut.disp_g.value == g and dut.disp_b.value == b, \
        f"RGB({dut.disp_r.value.integer},{dut.disp_g.value.integer},{dut.disp_b.value.integer}) is not RGB({r},{g},{b})."


def assert_coord(dut, x, y):
    """Assert coordinate is correct"""
    assert dut.disp_x.value == x and dut.disp_y.value == y, \
        f"({dut.disp_x.value.signed_integer},{dut.disp_y.value.signed_integer}) is not ({x},{y})."


def log_pixel(dut):
    """Log pixel at current position"""
    dut._log.info("RGB(%2d,%2d,%2d) at (%4d,%4d)", \
        dut.disp_r.value.integer, dut.disp_g.value.integer, dut.disp_b.value.integer, dut.disp_x.value.signed_integer, dut.disp_y.value.signed_integer)


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

    # await 4 ns into (0,0)
    await Timer(DISP_VBLANK*DISP_LINE*SYS_TIME + DISP_HBLANK*SYS_TIME + 4, units='ns')

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
    await Timer(377*DISP_LINE*SYS_TIME + 670*SYS_TIME, units='ns')  # 380=377+3 lines from above

    # pixel line 380
    assert_coord(dut, 670, 380)
    assert_pixel(dut, 0, 0, 0)  # black
    await Timer(SYS_TIME, units='ns')
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
