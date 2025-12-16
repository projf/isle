# Isle.Computer - Chapter 1 Test Bench
# Copyright Will Green

"""Chapter 1 Test Bench (cocotb)"""

import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer

TEST_INFO   =   1  # display test info (colour and coordinate) for passing tests
SYS_TIME    =  40  # 25 MHz - clock frequency

# 640x480 (DISPLAY_MODE=0)
DISP_LINE   = 800  # horizontal line including blanking
DISP_HBLANK = 160  # horizontal blanking
DISP_VBLANK =  45  # vertical blanking


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
