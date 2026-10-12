# Isle.Computer - Canvas Display AGU Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""canv_disp_agu Test Bench (cocotb)"""

import dataclasses
from dataclasses import dataclass

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge

from tests.helpers import Coords

PIX_TIME = 100  # 10 MHz pixel clock
RST_CYCLES = 10  # number of reset cycles before tests

# latencies (must match canv_disp_agu.mk)
CLUT_LAT = 1  # use different values for CLUT_LAT and VRAM_LAT to catch bugs
VRAM_LAT = 3
SCROLL_LAT = 2  # scroll register latency (must match canv_disp_agu.v)
ADDR_LAT = CLUT_LAT + VRAM_LAT  # address is output earlier...
DATA_LAT = CLUT_LAT  # ...so vram data aligns with paint and pixel index

@dataclass(frozen=True)
class CanvasParams:  # pylint: disable=too-many-instance-attributes
    """Hold display canvas parameters."""
    vram_addr_base: int
    addr_shift: int
    canv_dims: Coords
    disp_start: Coords
    disp_end: Coords
    win_start: Coords
    win_end: Coords
    scale: Coords
    scroll_coord: Coords = Coords(x=0, y=0)  # we have separate scroll tests


def scrolled(base, scroll_coord):
    """Create scrolled version of canvas params."""
    return dataclasses.replace(base, scroll_coord=scroll_coord)


SCALE_0X0Y = CanvasParams (
    vram_addr_base = 0x0,
    addr_shift = 3,  # 16 colour
    canv_dims = Coords(x=23, y=15),
    disp_start = Coords(x=-7, y=-2),
    disp_end = Coords(x=23, y=14),
    win_start = Coords(x=0, y=0),  # top left of display
    win_end = Coords(x=24, y=15),  # bottom right of display
    scale = Coords(x=0, y=0),  # hardware should treat as 1x
)

SCALE_1X1Y = CanvasParams (
    vram_addr_base = 0xC03,
    addr_shift = 5,  # 2 colour
    canv_dims = Coords(x=37, y=6),
    disp_start = Coords(x=-7, y=-2),
    disp_end = Coords(x=48, y=7),
    win_start = Coords(x=2, y=1),
    win_end = Coords(x=40, y=8),
    scale = Coords(x=1, y=1),
)

SCALE_2X2Y = CanvasParams (
    vram_addr_base = 0x201,
    addr_shift = 4,  # 4 colour
    canv_dims = Coords(x=32, y=16),
    disp_start = Coords(x=-15, y=-2),
    disp_end = Coords(x=67, y=38),
    win_start = Coords(x=1, y=1),  # 1 in from corner
    win_end = Coords(x=67, y=38),  # 1 in from corner
    scale = Coords(x=2, y=2),
)

SCALE_4X4Y = CanvasParams (
    vram_addr_base = 0x2000,
    addr_shift = 3,  # 16 colour
    canv_dims = Coords(x=16, y=4),
    disp_start = Coords(x=-7, y=-2),
    disp_end = Coords(x=23, y=14),
    win_start = Coords(x=0, y=0),
    win_end = Coords(x=24, y=15),
    scale = Coords(x=4, y=4),
)

SCALE_3X5Y = CanvasParams (
    vram_addr_base = 0x1FFF,
    addr_shift = 2,  # 256 colour
    canv_dims = Coords(x=12, y=7),
    disp_start = Coords(x=-7, y=-2),
    disp_end = Coords(x=15, y=7),
    win_start = Coords(x=2, y=1),
    win_end = Coords(x=16, y=8),
    scale = Coords(x=3, y=5),
)

LARGE_CANV = CanvasParams (
    vram_addr_base = 0x201,
    addr_shift = 4,  # 4 colour
    canv_dims = Coords(x=95, y=45),
    disp_start = Coords(x=-15, y=-2),
    disp_end = Coords(x=67, y=38),
    win_start = Coords(x=1, y=1),  # 1 in from corner
    win_end = Coords(x=67, y=38),  # 1 in from corner
    scale = Coords(x=2, y=2),
)

# this is very slow, so don't run routinely
FULL_DISP = CanvasParams (
    vram_addr_base = 0x201,
    addr_shift = 3,  # 16 colour
    canv_dims = Coords(x=24, y=15),
    disp_start = Coords(x=-153, y=-20),
    disp_end = Coords(x=671, y=383),
    win_start = Coords(x=1, y=1),  # 1 in from corner
    win_end = Coords(x=671, y=383),  # 1 in from corner
    scale = Coords(x=2, y=2),
)


def in_paint_area(p, x, y, scale_x, scale_y):
    """Is display position x,y within the canvas paint area?"""
    in_window = (p.win_start.x <= x < p.win_end.x
                 and p.win_start.y <= y < p.win_end.y)
    in_canv = (p.win_start.x <= x < p.win_start.x + p.canv_dims.x * scale_x
               and p.win_start.y <= y < p.win_start.y + p.canv_dims.y * scale_y)
    return in_window and in_canv


def calc_addr(p, dx, dy, scale_x, scale_y):
    """Calculate expected address for pixel in paint area."""
    # correct canvas paint position for latency and scale
    cx = (dx - p.win_start.x) // scale_x
    cy = (dy - p.win_start.y) // scale_y
    # calculate buffer position, accounting for wrapping
    bx = (p.scroll_coord.x + cx) % p.canv_dims.x
    by = (p.scroll_coord.y + cy) % p.canv_dims.y
    # calculate pixel address and separate into address and pixel index
    addr_pix = by * p.canv_dims.x + bx
    addr = p.vram_addr_base + (addr_pix >> p.addr_shift)
    pix_idx_mask = (1 << p.addr_shift) - 1
    pix_idx = addr_pix & pix_idx_mask
    return addr, pix_idx


def check(signal, expected, name, where):
    """Assert signal is resolvable and has expected value."""
    actual = signal.value
    assert actual.is_resolvable and int(actual) == expected, (
        f"{name}: '{actual}' is not expected '{expected}' {where}")


async def setup_dut(dut, p):
    """Setup DUT with clock, reset, and initial values."""
    Clock(dut.clk_pix, PIX_TIME, unit="ns").start()

    assert (0 <= p.scroll_coord.x < p.canv_dims.x
            and 0 <= p.scroll_coord.y < p.canv_dims.y), (
        f"bad test data: scroll coord {p.scroll_coord} "
        f"doesn't fit canvas {p.canv_dims}")

    # setup canvas before reset to flush AGU pipeline
    cordw = int(dut.CORDW.value)
    dut.dx.value = p.disp_start.x  # start of frame...
    dut.dy.value = p.disp_start.y  # ...so failed tests don't interfere
    dut.start.value = 0
    dut.line_start.value = 0
    dut.vram_addr_base.value = p.vram_addr_base
    dut.addr_shift.value = p.addr_shift
    dut.canv_dims.value = p.canv_dims.pack(width=cordw)
    dut.scale.value = p.scale.pack(width=cordw)
    dut.win_start.value = p.win_start.pack(width=cordw)
    dut.win_end.value = p.win_end.pack(width=cordw)
    dut.scroll_coord.value = p.scroll_coord.pack(width=cordw)

    # reset
    dut.rst_pix.value = 1
    await ClockCycles(dut.clk_pix, RST_CYCLES)
    dut.rst_pix.value = 0
    await RisingEdge(dut.clk_pix)


async def run_canvas_test(dut, p):
    """Test canvas display AGU outputs."""
    await setup_dut(dut, p)

    scale_x = p.scale.x or 1  # matches hardware behaviour
    scale_y = p.scale.y or 1

    for frame in range(2):  # test two frames
        for dy in range(p.disp_start.y, p.disp_end.y+1):
            for dx in range(p.disp_start.x, p.disp_end.x+1):
                dut.dy.value = dy
                dut.dx.value = dx
                dut.start.value = int(
                    dy == p.disp_start.y and dx == p.disp_start.x)
                dut.line_start.value = int(dx == p.disp_start.x)

                await ReadOnly()

                where = f"at ({dx}, {dy}) in frame={frame}"

                # vram_addr is for ADDR_LAT cycles from now
                addr_x = dx + ADDR_LAT
                if in_paint_area(p, addr_x, dy, scale_x, scale_y):
                    exp_addr, _ = calc_addr(p, addr_x, dy, scale_x, scale_y)
                    check(dut.vram_addr, exp_addr, "vram_addr", where)

                # pix_idx and paint are for DATA_LAT cycles from now
                data_x = dx + DATA_LAT
                exp_paint = in_paint_area(p, data_x, dy, scale_x, scale_y)
                check(dut.paint, int(exp_paint), "paint", where)
                if exp_paint:
                    _, exp_pix_idx = calc_addr(p, data_x, dy, scale_x, scale_y)
                    check(dut.pix_idx, exp_pix_idx, "pix_idx", where)

                await RisingEdge(dut.clk_pix)


@cocotb.test()  # pylint: disable=no-value-for-parameter
@cocotb.parametrize(p=[SCALE_0X0Y, SCALE_1X1Y, SCALE_2X2Y,
                       SCALE_4X4Y, SCALE_3X5Y, LARGE_CANV])
async def test_canvas(dut, p):
    """Test canvas display AGU outputs."""
    await run_canvas_test(dut, p)


@cocotb.test()  # pylint: disable=no-value-for-parameter
@cocotb.parametrize(p=[
    scrolled(SCALE_1X1Y, Coords(x=2,  y=0)),
    scrolled(SCALE_1X1Y, Coords(x=0,  y=3)),
    scrolled(SCALE_1X1Y, Coords(x=17, y=5)),
    scrolled(SCALE_3X5Y, Coords(x=5,  y=1))
])
async def test_scroll(dut, p):
    """Test canvas display AGU outputs with scrolling."""
    await run_canvas_test(dut, p)
