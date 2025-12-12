# Isle.Computer - Chapter 4 Test Bench
# Copyright Will Green

"""Chapter 4 Test Bench (cocotb)"""

import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer

TEST_INFO   =   1  # display test info (colour and coordinate) for passing tests
SYS_TIME    =  40  # 25 MHz - clock frequency
PIX_TIME    =  40  # 25 MHz - clock frequency
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


async def reset_sys_dut(dut):
    """Reset DUT (single cycle)"""
    await RisingEdge(dut.clk_sys)
    dut.rst_sys.value = 0
    await RisingEdge(dut.clk_sys)
    dut.rst_sys.value = 1
    await RisingEdge(dut.clk_sys)
    dut.rst_sys.value = 0
    await RisingEdge(dut.clk_sys)

async def reset_pix_dut(dut):
    """Reset DUT (single cycle)"""
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 0
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 1
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 0
    await RisingEdge(dut.clk_pix)


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def pixel_colour(dut):
    """Test display pixel colour"""
    cocotb.start_soon(Clock(dut.clk_sys, SYS_TIME, units="ns").start())
    await reset_sys_dut(dut)
    cocotb.start_soon(Clock(dut.clk_pix, PIX_TIME, units="ns").start())
    await reset_pix_dut(dut)

    # await 4 ns into (0,0)
    await Timer(DISP_VBLANK*DISP_LINE*SYS_TIME + DISP_HBLANK*SYS_TIME + 4, units='ns')

    # pixel line 0
    assert_coord(dut, 0, 0)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 1, 0)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(14*SYS_TIME, units='ns')
    assert_coord(dut, 15, 0)
    assert_pixel(dut, 31, 22, 00)  # 0xD
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 16, 0)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 17, 0)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(6*SYS_TIME, units='ns')
    assert_coord(dut, 23, 0)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 24, 0)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(646*SYS_TIME, units='ns')
    assert_coord(dut, 670, 0)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 671, 0)
    assert_pixel(dut, 23, 13, 21)  # 0x7
    await Timer((DISP_LINE-671)*SYS_TIME, units='ns')  # wait the rest of the line

    # pixel line 1
    assert_coord(dut, 0, 1)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 1, 1)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(14*SYS_TIME, units='ns')
    assert_coord(dut, 15, 1)
    assert_pixel(dut, 31, 22, 00)  # 0xD
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 16, 1)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 17, 1)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(6*SYS_TIME, units='ns')
    assert_coord(dut, 23, 1)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 24, 1)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(646*SYS_TIME, units='ns')
    assert_coord(dut, 670, 1)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 671, 1)
    assert_pixel(dut, 23, 13, 21)  # 0x7
    await Timer((DISP_LINE-671)*SYS_TIME, units='ns')  # wait the rest of the line

    # pixel line 2
    assert_coord(dut, 0, 2)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 1, 2)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(14*SYS_TIME, units='ns')
    assert_coord(dut, 15, 2)
    assert_pixel(dut, 31, 22, 00)  # 0xD
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 16, 2)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 17, 2)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(6*SYS_TIME, units='ns')
    assert_coord(dut, 23, 2)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 24, 2)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(646*SYS_TIME, units='ns')
    assert_coord(dut, 670, 2)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 671, 2)
    assert_pixel(dut, 23, 13, 21)  # 0x7
    await Timer((DISP_LINE-671)*SYS_TIME, units='ns')  # wait the rest of the line

    # skip to bottom of display
    await Timer(380*DISP_LINE*SYS_TIME, units='ns')

    # pixel line 383
    assert_coord(dut, 0, 383)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(8*SYS_TIME, units='ns')
    assert_coord(dut, 8, 383)
    assert_pixel(dut, 25, 14, 2)  # 0xC
    await Timer(663*SYS_TIME, units='ns')
    assert_coord(dut, 671, 383)
    assert_pixel(dut, 13, 7, 18)  # 0x6
    await Timer((DISP_LINE-671)*SYS_TIME, units='ns')  # wait the rest of the line

    # wait one more line to complete waveform
    await Timer(DISP_LINE*SYS_TIME, units='ns')
