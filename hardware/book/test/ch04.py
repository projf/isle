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

    #
    # top left of canvas
    #
    await Timer(DISP_VBLANK*DISP_LINE*SYS_TIME + DISP_HBLANK*SYS_TIME + 4, units='ns')  # await 4 ns into (0,0)
    assert_coord(dut, 0, 0)
    # assert_pixel(dut, 3, 2, 2)  # background

    #
    # bottom right of canvas
    #
    await Timer(383*DISP_LINE*SYS_TIME + 671*SYS_TIME, units='ns')  # 383 lines from above
    assert_coord(dut, 671, 383)
    # assert_pixel(dut, 3, 2, 2)  # background

    # wait one more line to complete waveform
    await Timer(DISP_LINE*SYS_TIME, units='ns')
