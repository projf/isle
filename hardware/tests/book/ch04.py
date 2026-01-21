# Isle.Computer - Chapter 4 Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Chapter 4 Test Bench (cocotb)"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from tests.helpers import assert_coord, assert_pixel

# clock frequencies
SYS_TIME = 25  # 25 ns is 40 MHz
PIX_TIME = 50  # 50 ns is 20 MHz

# 672x384 (DISPLAY_MODE=3)
DISP_LINE   = 825  # horizontal line including blanking
DISP_HBLANK = 153  # horizontal blanking
DISP_VBLANK =  20  # vertical blanking


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


async def pixel_colour_line_0(dut):
    """Test display pixel colour (line 0)"""
    assert_coord(dut, 0, 0)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 1, 0)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(14*PIX_TIME, unit='ns')
    assert_coord(dut, 15, 0)
    assert_pixel(dut, 31, 22, 00)  # 0xD
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 16, 0)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 17, 0)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(6*PIX_TIME, unit='ns')
    assert_coord(dut, 23, 0)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 24, 0)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(646*PIX_TIME, unit='ns')
    assert_coord(dut, 670, 0)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 671, 0)
    assert_pixel(dut, 23, 13, 21)  # 0x7
    await Timer((DISP_LINE-671)*PIX_TIME, unit='ns')  # wait the rest of the line


async def pixel_colour_line_1(dut):
    """Test display pixel colour (line 1)"""
    assert_coord(dut, 0, 1)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 1, 1)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(14*PIX_TIME, unit='ns')
    assert_coord(dut, 15, 1)
    assert_pixel(dut, 31, 22, 00)  # 0xD
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 16, 1)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 17, 1)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(6*PIX_TIME, unit='ns')
    assert_coord(dut, 23, 1)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 24, 1)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(646*PIX_TIME, unit='ns')
    assert_coord(dut, 670, 1)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 671, 1)
    assert_pixel(dut, 23, 13, 21)  # 0x7
    await Timer((DISP_LINE-671)*PIX_TIME, unit='ns')  # wait the rest of the line


async def pixel_colour_line_2(dut):
    """Test display pixel colour (line 2)"""
    assert_coord(dut, 0, 2)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 1, 2)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(14*PIX_TIME, unit='ns')
    assert_coord(dut, 15, 2)
    assert_pixel(dut, 31, 22, 00)  # 0xD
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 16, 2)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 17, 2)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(6*PIX_TIME, unit='ns')
    assert_coord(dut, 23, 2)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 24, 2)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(646*PIX_TIME, unit='ns')
    assert_coord(dut, 670, 2)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 671, 2)
    assert_pixel(dut, 23, 13, 21)  # 0x7
    await Timer((DISP_LINE-671)*PIX_TIME, unit='ns')  # wait the rest of the line


async def pixel_colour_line_383(dut):
    """Test display pixel colour (line 383)"""
    assert_coord(dut, 0, 383)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(8*PIX_TIME, unit='ns')
    assert_coord(dut, 8, 383)
    assert_pixel(dut, 25, 14, 2)  # 0xC
    await Timer(663*PIX_TIME, unit='ns')
    assert_coord(dut, 671, 383)
    assert_pixel(dut, 13, 7, 18)  # 0x6
    await Timer((DISP_LINE-671)*PIX_TIME, unit='ns')  # wait the rest of the line


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def pixel_colour(dut):
    """Test display pixel colour"""
    cocotb.start_soon(Clock(dut.clk_sys, SYS_TIME, unit="ns").start())
    await reset_sys_dut(dut)
    cocotb.start_soon(Clock(dut.clk_pix, PIX_TIME, unit="ns").start())
    await reset_pix_dut(dut)

    # await start of active pixels
    while not dut.de.value:
        await RisingEdge(dut.clk_pix)
    # await middle of clock before sampling colour
    await Timer(PIX_TIME >> 1, unit='ns')

    # pixel line 0
    await pixel_colour_line_0(dut)

    # pixel line 1
    await pixel_colour_line_1(dut)

    # pixel line 2
    await pixel_colour_line_2(dut)

    # skip to bottom of display
    await Timer(380*DISP_LINE*PIX_TIME, unit='ns')

    # pixel line 383
    await pixel_colour_line_383(dut)

    # wait one more line to complete waveform
    await Timer(DISP_LINE*PIX_TIME, unit='ns')
