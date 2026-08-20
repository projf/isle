# Isle.Computer - Canvas Draw AGU Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""canv_draw_agu Test Bench (cocotb)"""

import cocotb

from cocotb.clock import Clock
from cocotb.triggers import ReadOnly, RisingEdge
from cocotb.types import Logic

from tests.helpers import Coords

SYS_TIME = 100  # 10 MHz system clock
DRAW_ADDR_LAT = 4  # canv_draw_agu address latency (must match Verilog module)

# fixed test - will replace with selected random values soon
CANV_W = 336
CANV_H = 192
PIX_X = 29
PIX_Y = -97
VRAM_BASE_ADDR = 0x2004
ADDR_SHIFT = 5
DRAW_WRAP = 1


def wrapped(pix_x, pix_y, canv_w, canv_h, draw_wrap):
    """Calculate wrapped coordinates"""
    if draw_wrap:
        if pix_x < 0:
            pix_x += canv_w
        elif pix_x >= canv_w:
            pix_x -= canv_w
        if pix_y < 0:
            pix_y += canv_h
        elif pix_y >= canv_h:
            pix_y -= canv_h
    return pix_x, pix_y


def pix_offset(pix_x, pix_y, canv_w, pix_offsetw):
    """Calculate pixel offset."""
    mask = (1 << pix_offsetw) - 1
    return (canv_w * pix_y + pix_x) & mask


def expected_clip(pix_x, pix_y, canv_w, canv_h):
    """Expected clipping."""
    clip_x = (pix_x < 0 or pix_x >= canv_w)
    clip_y = (pix_y < 0 or pix_y >= canv_h)
    return clip_x or clip_y


def expected_pix_idx(offset, addr_shift):
    """Expected pix_idx."""
    mask = (1 << addr_shift) - 1
    return offset & mask


def expected_vram_addr(offset, addr_shift, vram_addr_base, addrw):
    """Expected vram_addr."""
    mask = (1 << addrw) - 1
    return (vram_addr_base + (offset >> addr_shift)) & mask


async def setup_dut(dut):
    """Setup DUT with clock."""
    Clock(dut.clk, SYS_TIME, unit="ns").start()

    # reset
    dut.rst.value = 0
    dut.en.value = 0
    await RisingEdge(dut.clk)
    dut.rst.value = 1
    for _ in range(DRAW_ADDR_LAT + 1):  # hold reset to cover pipeline
        await RisingEdge(dut.clk)
    dut.rst.value = 0


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def canv_draw_agu(dut):
    """Test canv_draw_agu."""
    await setup_dut(dut)
    addrw = int(dut.ADDRW.value)
    pix_offsetw = int(dut.PIX_OFFSETW.value)

    dut.en.value = 1
    dut.canv_dims.value = Coords(x=CANV_W, y=CANV_H).pack()
    dut.pix_coord.value = Coords(x=PIX_X, y=PIX_Y).pack()
    dut.addr_shift.value = ADDR_SHIFT
    dut.vram_addr_base.value = VRAM_BASE_ADDR
    dut.draw_wrap.value = DRAW_WRAP

    for _ in range(DRAW_ADDR_LAT):
        await RisingEdge(dut.clk)
    await ReadOnly()

    (pix_x, pix_y) = wrapped(PIX_X, PIX_Y, CANV_W, CANV_H, DRAW_WRAP)
    exp_clip = Logic(1) if (expected_clip(pix_x, pix_y, CANV_W, CANV_H)) else Logic(0)
    clip = dut.clip.value
    assert clip.is_resolvable and clip == exp_clip, (
        f"clip: '{dut.clip.value}' is not expected '{exp_clip}' "
        f"at ({PIX_X}, {PIX_Y})!"
    )

    if not exp_clip: #  if we aren't clipped, test address
        offset = pix_offset(pix_x, pix_y, CANV_W, pix_offsetw)

        exp_vram_addr = expected_vram_addr(offset, ADDR_SHIFT, VRAM_BASE_ADDR, addrw)
        vram_addr = dut.vram_addr.value
        assert vram_addr.is_resolvable and int(vram_addr) == exp_vram_addr, (
            f"vram_addr: '{vram_addr}' is not expected '{exp_vram_addr}' "
            f"at ({PIX_X}, {PIX_Y})!"
        )

        exp_pix_idx = expected_pix_idx(offset, ADDR_SHIFT)
        pix_idx = dut.pix_idx.value
        assert pix_idx.is_resolvable and int(pix_idx) == exp_pix_idx, (
            f"pix_idx: '{pix_idx}' is not expected '{exp_pix_idx}' "
            f"at ({PIX_X}, {PIX_Y})!"
        )
