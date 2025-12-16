# Isle.Computer - Chapter 3 Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Chapter 3 Test Bench (cocotb)"""

import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer

TEST_INFO   =   1  # display test info (colour and coordinate) for passing tests
SYS_TIME    =  40  # 25 MHz clock frequency (for system and pixel clocks)

# 672x384 (DISPLAY_MODE=3)
DISP_LINE   = 800  # horizontal line including blanking
DISP_HBLANK = 128  # horizontal blanking
DISP_VBLANK = 137  # vertical blanking


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


async def zero_memory(dut):
    """Zero vram and to match hardware behaviour for block ram."""

    for i in range(2**dut.VRAM_ADDRW.value):
        dut.vram_inst.wmask_sys.value = 0xFFFFFFFF
        dut.vram_inst.addr_sys.value = i
        dut.vram_inst.din_sys.value = 0
        await RisingEdge(dut.clk_sys)

    dut.vram_inst.wmask_sys.value = 0x00000000
    await RisingEdge(dut.clk_sys)


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def pixel_colour(dut):
    """Test display pixel colour"""
    dut.er_start.value = 0
    cocotb.start_soon(Clock(dut.clk_pix, SYS_TIME, units="ns").start())
    cocotb.start_soon(Clock(dut.clk_sys, SYS_TIME, units="ns").start())

    # await initialize_cdc(dut)
    await reset_pix_dut(dut)
    await reset_sys_dut(dut)

    # zero vram otherwise we'll paint x
    await zero_memory(dut)
    await RisingEdge(dut.clk_sys)

    # start Earthrise
    dut.er_start.value = 1
    await RisingEdge(dut.clk_sys)
    dut.er_start.value = 0
    await RisingEdge(dut.clk_sys)

    # await start of active pixels
    while not dut.de.value:
        await RisingEdge(dut.clk_pix)
    # await middle of clock before sampling colour
    await Timer(SYS_TIME >> 1, units='ns')

    # pixel line 0
    assert_coord(dut, 0, 0)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(DISP_LINE*SYS_TIME, units='ns')  # wait the rest of the line

    # pixel line 1
    assert_coord(dut, 0, 1)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 1, 1)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 2, 1)
    assert_pixel(dut, 0, 11, 17)  # 0x1
    await Timer((DISP_LINE-2)*SYS_TIME, units='ns')  # wait the rest of the line

    #
    # add remaining tests here...
    #

    # skip to bottom of display
    await Timer(381*DISP_LINE*SYS_TIME + 671*SYS_TIME, units='ns')  # 380=377+3 lines from above

    assert_coord(dut, 671, 383)
    assert_pixel(dut, 0, 5, 11)  # 0x0

    # wait one more line to complete waveform
    await Timer(DISP_LINE*SYS_TIME, units='ns')
