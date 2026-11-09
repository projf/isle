# Isle.Computer - Chapter 6 Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Chapter 6 Test Bench (cocotb)
Just for waveform generation at present."""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from tests.helpers import assert_coord, assert_pixel

# clock frequency
SYS_TIME = 50  # 50 ns is 20 MHz
PIX_TIME = 20  # 20 ns is 50 MHz

# 640x360 (DISPLAY_MODE=0)
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


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def test_ch06(dut):
    """ch06 test"""
    cocotb.start_soon(Clock(dut.clk_sys, SYS_TIME, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_pix, PIX_TIME, unit="ns").start())
    await reset_sys_dut(dut)
    await reset_pix_dut(dut)

    await Timer(500*SYS_TIME, unit='ns')  # for simple software
    # await Timer(20, unit='ms')  # two frames for testing frame waiting
