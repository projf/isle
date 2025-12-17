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

    await Timer(1*DISP_LINE*SYS_TIME, units='ns')

    # line 1
    # pixel
    assert_coord(dut, 0, 1)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 1, 1)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 2, 1)
    assert_pixel(dut, 0, 11, 17)  # 0x1
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 3, 1)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer((DISP_LINE-3)*SYS_TIME, units='ns')  # wait the rest of the line

    await Timer(3*DISP_LINE*SYS_TIME, units='ns')

    # line 5
    # horizontal line
    assert_coord(dut, 0, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 1, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 2, 5)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 3, 5)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 4, 5)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 5, 5)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 6, 5)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 7, 5)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 8, 5)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 9, 5)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 10, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 11, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 12, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    # rect
    assert_coord(dut, 13, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 14, 5)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 15, 5)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 16, 5)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 17, 5)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 18, 5)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 19, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 20, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    # triangle
    assert_coord(dut, 21, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 22, 5)
    assert_pixel(dut, 0, 11, 17)  # 0x1
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 23, 5)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 24, 5)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 25, 5)
    assert_pixel(dut, 0, 11, 17)  # 0x1
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 26, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer((DISP_LINE-26)*SYS_TIME, units='ns')  # wait the rest of the line

    await Timer(3*DISP_LINE*SYS_TIME, units='ns')

    # line 9
    # triangle
    await Timer(21*SYS_TIME, units='ns')
    assert_coord(dut, 21, 9)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 22, 9)
    assert_pixel(dut, 0, 11, 17)  # 0x1
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 23, 9)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 24, 9)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 25, 9)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 26, 9)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 27, 9)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 28, 9)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 29, 9)
    assert_pixel(dut, 0, 11, 17)  # 0x1
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 30, 9)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer((DISP_LINE-30)*SYS_TIME, units='ns')  # wait the rest of the line

    await Timer(2*DISP_LINE*SYS_TIME, units='ns')

    # line 12
    # diagonal line
    assert_coord(dut, 0, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 1, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 2, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 3, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 4, 12)
    assert_pixel(dut, 0, 11, 17)  # 0x1
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 5, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(8*SYS_TIME, units='ns')
    # circle
    assert_coord(dut, 13, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 14, 12)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 15, 12)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 16, 12)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 17, 12)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 18, 12)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 19, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
    assert_coord(dut, 20, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(SYS_TIME, units='ns')
