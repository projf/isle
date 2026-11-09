# Isle.Computer - Chapter 4 Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Chapter 4 Test Bench (cocotb)"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from tests.helpers import assert_coord, assert_pixel

# clock frequencies
SYS_TIME = 50  # 50 ns is 20 MHz
PIX_TIME = 20  # 20 ns is 50 MHz

# 640x360 (DISPLAY_MODE=0) with 640x352 graphics
DISP_LINE   = 888  # horizontal line including blanking
DISP_HBLANK = 248  # horizontal blanking
DISP_VBLANK =  15  # vertical blanking


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


async def pixel_colour_line_4(dut):
    """Test display pixel colour (line 4)"""
    assert_coord(dut, 0, 4)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 1, 4)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(14*PIX_TIME, unit='ns')
    assert_coord(dut, 15, 4)
    assert_pixel(dut, 31, 22, 00)  # 0xD
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 16, 4)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 17, 4)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(6*PIX_TIME, unit='ns')
    assert_coord(dut, 23, 4)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 24, 4)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(614*PIX_TIME, unit='ns')
    assert_coord(dut, 638, 4)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 639, 4)
    assert_pixel(dut, 23, 13, 21)  # 0x7
    await Timer((DISP_LINE-639)*PIX_TIME, unit='ns')  # wait the rest of the line


async def pixel_colour_line_5(dut):
    """Test display pixel colour (line 5)"""
    assert_coord(dut, 0, 5)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 1, 5)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(14*PIX_TIME, unit='ns')
    assert_coord(dut, 15, 5)
    assert_pixel(dut, 31, 22, 00)  # 0xD
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 16, 5)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 17, 5)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(6*PIX_TIME, unit='ns')
    assert_coord(dut, 23, 5)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 24, 5)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(614*PIX_TIME, unit='ns')
    assert_coord(dut, 638, 5)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 639, 5)
    assert_pixel(dut, 23, 13, 21)  # 0x7
    await Timer((DISP_LINE-639)*PIX_TIME, unit='ns')  # wait the rest of the line


async def pixel_colour_line_6(dut):
    """Test display pixel colour (line 6)"""
    assert_coord(dut, 0, 6)
    assert_pixel(dut, 0, 22, 13)  # 0x5
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 1, 6)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(14*PIX_TIME, unit='ns')
    assert_coord(dut, 15, 6)
    assert_pixel(dut, 31, 22, 00)  # 0xD
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 16, 6)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 17, 6)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(6*PIX_TIME, unit='ns')
    assert_coord(dut, 23, 6)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 24, 6)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(614*PIX_TIME, unit='ns')
    assert_coord(dut, 638, 6)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(PIX_TIME, unit='ns')
    assert_coord(dut, 639, 6)
    assert_pixel(dut, 23, 13, 21)  # 0x7
    await Timer((DISP_LINE-639)*PIX_TIME, unit='ns')  # wait the rest of the line


async def pixel_colour_line_355(dut):
    """Test display pixel colour (line 355)"""
    assert_coord(dut, 0, 355)
    assert_pixel(dut, 28, 28, 25)  # 0xF
    await Timer(8*PIX_TIME, unit='ns')
    assert_coord(dut, 8, 355)
    assert_pixel(dut, 3, 2, 3)  # 0x0
    await Timer(631*PIX_TIME, unit='ns')
    assert_coord(dut, 639, 355)
    assert_pixel(dut, 3, 2, 3)   # 0x0
    await Timer((DISP_LINE-639)*PIX_TIME, unit='ns')  # wait the rest of the line


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def text_pixel_colour(dut):
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

    # skip to line 4 (after letterbox)
    await Timer(4*DISP_LINE*PIX_TIME, unit='ns')

    # pixel line 4
    await pixel_colour_line_4(dut)

    # pixel line 5
    await pixel_colour_line_5(dut)

    # pixel line 6
    await pixel_colour_line_6(dut)

    # skip to bottom of display
    await Timer(348*DISP_LINE*PIX_TIME, unit='ns')

    # pixel line 355
    await pixel_colour_line_355(dut)

    # wait until line 360 to complete waveform
    await Timer(5*DISP_LINE*SYS_TIME, unit='ns')
