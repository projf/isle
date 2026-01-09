# Isle.Computer - Chapter 3 Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Chapter 3 Test Bench (cocotb)"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from tests.helpers import assert_coord, assert_pixel, zero_vram

# clock frequencies
SYS_TIME = 40  # 40 ns is 25 MHz
PIX_TIME = 20  # 20 ns is 50 MHz

# 672x384 (DISPLAY_MODE=3)
DISP_LINE   = 800  # horizontal line including blanking
DISP_HBLANK = 128  # horizontal blanking
DISP_VBLANK = 137  # vertical blanking


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


async def pixel_colour_line_1(dut):
    """Test display pixel colour (line 1)"""
    # pixel
    assert_coord(dut, 0, 1)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 1, 1)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 2, 1)
    assert_pixel(dut, 0, 11, 17)  # 0x1
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 3, 1)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer((DISP_LINE-3)*PIX_TIME, unit='ns')  # wait the rest of the line


async def pixel_colour_line_5(dut):
    """Test display pixel colour (line 5)"""
    # horizontal line
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 1, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 2, 5)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(7*PIX_TIME, unit='ns')
    assert_coord(dut, 9, 5)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 10, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(3*PIX_TIME, unit='ns')
    # rect
    assert_coord(dut, 13, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 14, 5)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 15, 5)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(2*PIX_TIME, unit='ns')
    assert_coord(dut, 17, 5)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 18, 5)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 19, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(2*PIX_TIME, unit='ns')
    # triangle
    assert_coord(dut, 21, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 22, 5)
    assert_pixel(dut, 0, 11, 17)  # 0x1
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 23, 5)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 24, 5)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 25, 5)
    assert_pixel(dut, 0, 11, 17)  # 0x1
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 26, 5)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer((DISP_LINE-26)*PIX_TIME, unit='ns')  # wait the rest of the line


async def pixel_colour_line_9(dut):
    """Test display pixel colour (line 9)"""
    # triangle
    await Timer(21*PIX_TIME, unit='ns')
    assert_coord(dut, 21, 9)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 22, 9)
    assert_pixel(dut, 0, 11, 17)  # 0x1
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 23, 9)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 24, 9)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 25, 9)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 26, 9)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 27, 9)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 28, 9)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 29, 9)
    assert_pixel(dut, 0, 11, 17)  # 0x1
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 30, 9)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer((DISP_LINE-30)*PIX_TIME, unit='ns')  # wait the rest of the line


async def pixel_colour_line_12(dut):
    """Test display pixel colour (line 12)"""
    # diagonal line
    assert_coord(dut, 0, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 1, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 2, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 3, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 4, 12)
    assert_pixel(dut, 0, 11, 17)  # 0x1
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 5, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(8*PIX_TIME, unit='ns')
    # circle
    assert_coord(dut, 13, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 14, 12)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 15, 12)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 16, 12)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 17, 12)
    assert_pixel(dut, 19, 30, 28)  # 0x3
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 18, 12)
    assert_pixel(dut, 0, 23, 23)  # 0x2
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 19, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 20, 12)
    assert_pixel(dut, 0, 5, 11)  # 0x0
    await Timer(PIX_TIME, unit='ns')


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def pixel_colour(dut):
    """Test display pixel colour"""
    dut.er_start.value = 0
    cocotb.start_soon(Clock(dut.clk_sys, SYS_TIME, unit="ns").start())
    await reset_sys_dut(dut)
    cocotb.start_soon(Clock(dut.clk_pix, PIX_TIME, unit="ns").start())
    await reset_pix_dut(dut)

    # zero vram otherwise we'll paint x
    await zero_vram(dut.vram_inst)
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
    await Timer(PIX_TIME >> 1, unit='ns')

    # line 1
    await Timer(1*DISP_LINE*PIX_TIME, unit='ns')
    await pixel_colour_line_1(dut)

    # line 5
    await Timer(3*DISP_LINE*PIX_TIME, unit='ns')
    await pixel_colour_line_5(dut)

    # line 9
    await Timer(3*DISP_LINE*PIX_TIME, unit='ns')
    await pixel_colour_line_9(dut)

    # line 12
    await Timer(2*DISP_LINE*PIX_TIME, unit='ns')
    await pixel_colour_line_12(dut)
