# Isle.Computer - Canvas Display AGU Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""canv_disp_agu Test Bench (cocotb)"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

# clock frequencies
PIX_TIME = 100  # 10 MHz

# test display 16x8 pixels
X_MIN = -7
X_MAX = 15
Y_MIN = -2
Y_MAX = 7

@cocotb.test()  # pylint: disable=no-value-for-parameter
async def address_scale_0x(dut):
    """Test address calculation."""

    cocotb.start_soon(Clock(dut.clk_pix, PIX_TIME, units="ns").start())

    # reset
    dut.rst_pix.value = 0
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 1
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 0
    await RisingEdge(dut.clk_pix)

    # setup canvas
    dut.addr_base.value = 12  # base address 0xC
    dut.addr_shift.value = 3  # 16 colour
    dut.win_start.value = 0x00000000  # (0,0)
    dut.win_end.value = 0x00080010  # (height=8,width=16)
    dut.scale.value = 0x0000000 # 0x in both dimensions (should become 1x)

    for dy in range(Y_MIN, Y_MAX+1):
        for dx in range(X_MIN, X_MAX+1):
            dut.dy.value = dy
            dut.dx.value = dx
            dut.line_start.value = 1 if dx == X_MIN else 0
            await RisingEdge(dut.clk_pix)


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def address_scale_1x(dut):
    """Test address calculation."""

    cocotb.start_soon(Clock(dut.clk_pix, PIX_TIME, units="ns").start())

    # reset
    dut.rst_pix.value = 0
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 1
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 0
    await RisingEdge(dut.clk_pix)

    # setup canvas
    dut.addr_base.value = 12  # base address 0xC
    dut.addr_shift.value = 3  # 16 colour
    dut.win_start.value = 0x00000000  # (0,0)
    dut.win_end.value = 0x00080010  # (height=8,width=16)
    dut.scale.value = 0x00010001 # 1x in both dimensions

    for dy in range(Y_MIN, Y_MAX+1):
        for dx in range(X_MIN, X_MAX+1):
            dut.dy.value = dy
            dut.dx.value = dx
            dut.line_start.value = 1 if dx == X_MIN else 0
            await RisingEdge(dut.clk_pix)


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def address_scale_2x(dut):
    """Test address calculation."""

    cocotb.start_soon(Clock(dut.clk_pix, PIX_TIME, units="ns").start())

    # reset
    dut.rst_pix.value = 0
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 1
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 0
    await RisingEdge(dut.clk_pix)

    # setup canvas
    dut.addr_base.value = 12  # base address 0xC
    dut.addr_shift.value = 3  # 16 colour
    dut.win_start.value = 0x00000000  # (0,0)
    dut.win_end.value = 0x00080010  # (height=8,width=16)
    dut.scale.value = 0x00020002 # 2x in both dimensions

    for dy in range(Y_MIN, Y_MAX+1):
        for dx in range(X_MIN, X_MAX+1):
            dut.dy.value = dy
            dut.dx.value = dx
            dut.line_start.value = 1 if dx == X_MIN else 0
            await RisingEdge(dut.clk_pix)
