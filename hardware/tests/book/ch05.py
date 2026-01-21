# Isle.Computer - Chapter 5 Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Chapter 5 Test Bench (cocotb)"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from tests.helpers import assert_coord, assert_pixel

# clock frequency
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


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def ch05(dut):
    """ch05 test"""
    cocotb.start_soon(Clock(dut.clk_sys, SYS_TIME, unit="ns").start())
    cocotb.start_soon(Clock(dut.clk_pix, PIX_TIME, unit="ns").start())
    await reset_sys_dut(dut)
    await reset_pix_dut(dut)

    await Timer(500*SYS_TIME, unit='ns')  # for simple software
    # await Timer(20, unit='ms')  # two frames for testing frame waiting
