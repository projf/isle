# Isle.Computer - Canvas Draw AGU Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""canv_draw_agu Test Bench (cocotb)"""

# To Do
#  - add edge test
#  - add pipeline test
#  - add en (enable) test

from dataclasses import dataclass
from random import randint

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ReadOnly, RisingEdge
from cocotb.types import Logic

from tests.helpers import Coords

SYS_TIME = 100  # 10 MHz system clock
DRAW_ADDR_LAT = 4  # canv_draw_agu address latency (must match Verilog module)

# random testing params
RAND_TEST_CNT = 5000  # number of random pixels to test
CANV_W_MAX = 84  # not too large so we focus on the interesting edges
CANV_H_MAX = 41
EDGE_MARGIN = 19  # number of pixels to test outside normal canvas range
ADDR_SHIFT_MIN = 2  # matches Earthrise
ADDR_SHIFT_MAX = 5


@dataclass(frozen=True)
class DrawParams:
    """Hold draw AGU parameters."""
    canv_dims: Coords
    pix_coord: Coords
    vram_addr_base: int
    addr_shift: int
    wraph: bool
    wrapv: bool


@dataclass(frozen=True)
class ModuleWidths:
    """Verilog module widths read from DUT params."""
    addrw: int
    cordw: int
    pix_offsetw: int


# single fixed test with wrapping
FIXED_TEST_PARAMS = DrawParams (
    canv_dims = Coords(x=336, y=192),
    pix_coord = Coords(x=29, y=-97),
    vram_addr_base = 0x2004,
    addr_shift = 5,
    wraph = True,
    wrapv = True
)


def wrapped(pix, canv, wrap):
    """Calculate wrapped coordinates"""
    if wrap:
        if pix < 0:
            pix += canv
        elif pix >= canv:
            pix -= canv
    return pix


def random_params(widths):
    """Generate random draw test params."""
    canv_w = randint(0, CANV_W_MAX)
    canv_h = randint(0, CANV_H_MAX)
    pix_x = randint(-(canv_w+EDGE_MARGIN), 2*canv_w+EDGE_MARGIN)
    pix_y = randint(-(canv_h+EDGE_MARGIN), 2*canv_h+EDGE_MARGIN)

    assert canv_w * canv_h <= (1 << widths.pix_offsetw), (
        f"bad test data: canvas {canv_w}x{canv_h} exceeds addressable pixels"
    )

    return DrawParams(
        canv_dims = Coords(x=canv_w, y=canv_h),
        pix_coord = Coords(x=pix_x, y=pix_y),
        vram_addr_base = randint(0, (1 << widths.addrw) - 1),
        addr_shift = randint(ADDR_SHIFT_MIN, ADDR_SHIFT_MAX),
        wraph = bool(randint(0, 1)),
        wrapv = bool(randint(0, 1))
    )


def module_widths(dut):
    """Verilog module width parameters."""
    return ModuleWidths(
        addrw = int(dut.ADDRW.value),
        cordw = int(dut.CORDW.value),
        pix_offsetw = int(dut.PIX_OFFSETW.value)
    )


def expected(p, widths):
    """Expected values for a canvas draw. Follows Verilog pipeline stages."""
    # stage 1 - canvas wrap
    pix_x = wrapped(p.pix_coord.x, p.canv_dims.x, p.wraph)
    pix_y = wrapped(p.pix_coord.y, p.canv_dims.y, p.wrapv)
    # stage 2 - check validity
    valid = (0 <= pix_x < p.canv_dims.x and 0 <= pix_y < p.canv_dims.y)
    # stage 3 - pixel offset from start of canvas
    offset_mask = (1 << widths.pix_offsetw) - 1
    offset = (p.canv_dims.x * pix_y + pix_x) & offset_mask
    # stage 4 - vram address and pixel ID
    vram_addr_mask = (1 << widths.addrw) - 1
    vram_addr = (p.vram_addr_base + (offset >> p.addr_shift)) & vram_addr_mask
    pix_idx_mask = (1 << p.addr_shift) - 1
    pix_idx = offset & pix_idx_mask
    return (valid, vram_addr, pix_idx)


async def check_pixel(dut, p, widths):
    """Check AGU output for single pixel."""
    dut.canv_dims.value = p.canv_dims.pack(width=widths.cordw)
    dut.pix_coord.value = p.pix_coord.pack(width=widths.cordw)
    dut.addr_shift.value = p.addr_shift
    dut.vram_addr_base.value = p.vram_addr_base
    dut.wraph.value = p.wraph
    dut.wrapv.value = p.wrapv

    # wait for pipeline before checking results
    for _ in range(DRAW_ADDR_LAT):
        await RisingEdge(dut.clk)

    await ReadOnly()
    valid = dut.valid.value
    vram_addr = dut.vram_addr.value
    pix_idx = dut.pix_idx.value
    await RisingEdge(dut.clk)  # leave ReadOnly state so the caller can drive again

    (exp_valid, exp_vram_addr, exp_pix_idx) = expected(p, widths)
    where_str = (f"at {p.pix_coord} in {p.canv_dims} shift={p.addr_shift} "
                 f"wrap(h={p.wraph:d}, v={p.wrapv:d})")

    assert valid.is_resolvable and valid == (Logic(1) if exp_valid else Logic(0)), (
        f"valid: '{valid}' is not expected '{exp_valid:d}' {where_str}!"
    )

    if not exp_valid:  # when not valid, vram address and pixel ID are undefined
        return

    assert vram_addr.is_resolvable and int(vram_addr) == exp_vram_addr, (
        f"vram_addr: '{vram_addr}' is not expected '{exp_vram_addr}' {where_str}!"
    )
    assert pix_idx.is_resolvable and int(pix_idx) == exp_pix_idx, (
        f"pix_idx: '{pix_idx}' is not expected '{exp_pix_idx}' {where_str}!"
    )


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
async def canv_draw_agu_random(dut):
    """Test many random canv_draw_agu cases."""
    await setup_dut(dut)
    dut.en.value = 1  # always enabled; we'll use a separate test for this
    widths = module_widths(dut)  # width parameters from dut

    for _ in range(RAND_TEST_CNT):
        p = random_params(widths)
        await check_pixel(dut, p, widths)


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def canv_draw_agu_fixed(dut):
    """Test canv_draw_agu with single fixed case."""
    await setup_dut(dut)
    dut.en.value = 1  # always enabled; we'll use a separate test for this
    widths = module_widths(dut)
    await check_pixel(dut, FIXED_TEST_PARAMS, widths)
