# Isle.Computer - Display Controller Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Display Controller Test Bench (cocotb)"""

import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from display_data import DT

# create test params from display timings selected by env var
mode         = int(os.getenv("DISPLAY_MODE"))
hres         =  DT[mode]['HRES']
vres         =  DT[mode]['VRES']
pix_time     =  DT[mode]['PIX_TIME']
line_start   = -DT[mode]['H_BLANK']
line_end     =  DT[mode]['HRES']-1
h_sync_start = -DT[mode]['H_BLANK'] + DT[mode]['H_FRONT']
h_sync_end   = -DT[mode]['H_BLANK'] + DT[mode]['H_FRONT'] + DT[mode]['H_SYNC']
h_pol        =  DT[mode]['H_POL']
frame_start  = -DT[mode]['V_BLANK']
frame_end    =  DT[mode]['VRES']-1
v_sync_start = -DT[mode]['V_BLANK'] + DT[mode]['V_FRONT']
v_sync_end   = -DT[mode]['V_BLANK'] + DT[mode]['V_FRONT'] + DT[mode]['V_SYNC']
v_pol        =  DT[mode]['V_POL']

async def reset_dut(dut):
    """Reset DUT (single cycle)"""
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 0
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 1
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 0
    await RisingEdge(dut.clk_pix)

@cocotb.test()  # pylint: disable=no-value-for-parameter
async def display_res_freq(dut):
    """Test mode resolution and frequency"""
    cocotb.start_soon(Clock(dut.clk_pix, pix_time, unit="ns").start())
    await reset_dut(dut)

    await RisingEdge(dut.clk_pix)
    assert dut.hres.value.to_signed() == hres, \
        f"hres {dut.hres.value.to_signed()} is not {hres}!"
    assert dut.vres.value.to_signed() == vres, \
        f"vres {dut.vres.value.to_signed()} is not {vres}!"

@cocotb.test()  # pylint: disable=no-value-for-parameter
async def display_de(dut):
    """Test data enable"""
    cocotb.start_soon(Clock(dut.clk_pix, pix_time, unit="ns").start())
    await reset_dut(dut)

    # de start
    while not dut.de.value:
        await RisingEdge(dut.clk_pix)
    assert dut.dx.value.to_signed() == 0, \
        f"x {dut.dx.value.to_signed()} is not 0 at de start!"
    assert dut.dy.value.to_signed() == 0, \
        f"y {dut.dy.value.to_signed()} is not 0 at de start!"

@cocotb.test()  # pylint: disable=no-value-for-parameter
async def display_line(dut):
    """Test line timings"""
    cocotb.start_soon(Clock(dut.clk_pix, pix_time, unit="ns").start())
    await reset_dut(dut)

    # line start
    assert dut.dx.value.to_signed() == line_start, \
        f"line start {dut.dx.value.to_signed()} is not {line_start}!"

    # sync start
    if h_pol:  # positive polarity
        while not dut.hsync.value:
            await RisingEdge(dut.clk_pix)
    else:
        while dut.hsync.value:
            await RisingEdge(dut.clk_pix)
    assert dut.dx.value.to_signed() == h_sync_start, \
        f"hsync start {dut.dx.value.to_signed()} is not {h_sync_start}!"

    # sync end
    if h_pol:
        while dut.hsync.value:
            await RisingEdge(dut.clk_pix)
    else:
        while not dut.hsync.value:
            await RisingEdge(dut.clk_pix)
    assert dut.dx.value.to_signed() == h_sync_end, f"hsync end {h_sync_end}!"

    # line end
    while not dut.line_start.value:
        dx_prev = dut.dx.value.to_signed()
        await RisingEdge(dut.clk_pix)
    assert dx_prev == line_end, \
        f"line end {dx_prev} is not {line_end}!"

@cocotb.test()  # pylint: disable=no-value-for-parameter
async def display_frame(dut):
    """Test frame timings"""
    cocotb.start_soon(Clock(dut.clk_pix, pix_time, unit="ns").start())
    await reset_dut(dut)

    # frame start
    assert dut.dy.value.to_signed() == frame_start, \
        f"frame start {dut.dy.value.to_signed()} is not {frame_start}!"

    # sync start (positive polarity)
    if v_pol:
        while not dut.vsync.value:
            await RisingEdge(dut.clk_pix)
    else:
        while dut.vsync.value:
            await RisingEdge(dut.clk_pix)
    assert dut.dy.value.to_signed() == v_sync_start, \
        f"vsync start {dut.dy.value.to_signed()} is not {v_sync_start}!"

    # sync end
    if v_pol:
        while dut.vsync.value:
            await RisingEdge(dut.clk_pix)
    else:
        while not dut.vsync.value:
            await RisingEdge(dut.clk_pix)
    assert dut.dy.value.to_signed() == v_sync_end, \
        f"vsync end {dut.dy.value.to_signed()} is not {v_sync_end}!"

    # frame end
    while not dut.frame_start.value:
        dx_prev = dut.dx.value.to_signed()
        dy_prev = dut.dy.value.to_signed()
        await RisingEdge(dut.clk_pix)
    assert dy_prev == frame_end, \
        f"frame end line {dy_prev} is not {frame_end}!"
    assert dx_prev == line_end, \
        f"frame end pixel {dx_prev} is not {line_end}!"
