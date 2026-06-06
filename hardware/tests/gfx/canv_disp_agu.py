# Isle.Computer - Canvas Display AGU Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""canv_disp_agu Test Bench (cocotb)"""

from dataclasses import dataclass

import cocotb

from cocotb.clock import Clock
from cocotb.triggers import ReadOnly, RisingEdge
from cocotb.types import Logic

from tests.helpers import Coords

# clock frequencies
PIX_TIME = 100  # 10 MHz

# latencies (must match canv_disp_agu.mk)
CLUT_LAT = 1
VRAM_LAT = 3
ADDR_LAT = CLUT_LAT + VRAM_LAT

@dataclass(frozen=True)
class CanvasParams:
    """Hold canvas parameters."""
    addr_base: int
    addr_shift: int
    disp_start: Coords
    disp_end: Coords
    win_start: Coords
    win_end: Coords
    scale: Coords


SCALE_0X0Y = CanvasParams (
    addr_base = 0x0,
    addr_shift = 3,  # 16 colour
    disp_start = Coords(x=-7, y=-2),
    disp_end = Coords(x=23, y=14),
    win_start = Coords(x=0, y=0),  # top left of display
    win_end = Coords(x=24, y=15),  # bottom right of display
    scale = Coords(x=0, y=0),  # hardware should treat as 1x
)

SCALE_1X1Y = CanvasParams (
    addr_base = 0xC03,
    addr_shift = 5,  # 2 colour
    disp_start = Coords(x=-7, y=-2),
    disp_end = Coords(x=15, y=7),
    win_start = Coords(x=2, y=1),
    win_end = Coords(x=16, y=8),
    scale = Coords(x=1, y=1),
)

SCALE_2X2Y = CanvasParams (
    addr_base = 0x201,
    addr_shift = 4,  # 4 colour
    disp_start = Coords(x=-15, y=-2),
    disp_end = Coords(x=67, y=38),
    win_start = Coords(x=1, y=1),  # 1 in from corner
    win_end = Coords(x=67, y=38),  # 1 in from corner
    scale = Coords(x=2, y=2),
)

SCALE_4X4Y = CanvasParams (
    addr_base = 0x2000,
    addr_shift = 3,  # 16 colour
    disp_start = Coords(x=-7, y=-2),
    disp_end = Coords(x=23, y=14),
    win_start = Coords(x=0, y=0),
    win_end = Coords(x=24, y=15),
    scale = Coords(x=4, y=4),
)

SCALE_3X5Y = CanvasParams (
    addr_base = 0x1FFF,
    addr_shift = 2,  # 256 colour
    disp_start = Coords(x=-7, y=-2),
    disp_end = Coords(x=15, y=7),
    win_start = Coords(x=2, y=1),
    win_end = Coords(x=16, y=8),
    scale = Coords(x=3, y=5),
)

FULL_DISP = CanvasParams (
    addr_base = 0x201,
    addr_shift = 4,  # 4 colour
    disp_start = Coords(x=-153, y=-20),
    disp_end = Coords(x=671, y=383),
    win_start = Coords(x=1, y=1),  # 1 in from corner
    win_end = Coords(x=671, y=383),  # 1 in from corner
    scale = Coords(x=2, y=2),
)


@cocotb.test()  # pylint: disable=no-value-for-parameter
@cocotb.parametrize(p=[SCALE_0X0Y, SCALE_1X1Y, SCALE_2X2Y, SCALE_4X4Y, SCALE_3X5Y, FULL_DISP])
async def canv_disp_agu_paint(dut, p):
    """Test canvas display AGU paint signal."""
    cocotb.start_soon(Clock(dut.clk_pix, PIX_TIME, unit="ns").start())

    # reset
    dut.rst_pix.value = 0
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 1
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 0
    await RisingEdge(dut.clk_pix)

    # setup canvas
    dut.addr_base.value = p.addr_base
    dut.addr_shift.value = p.addr_shift
    dut.win_start.value = p.win_start.pack()
    dut.win_end.value = p.win_end.pack()
    dut.scale.value = p.scale.pack()

    for frame in range(2):  # test two frames
        for dy in range(p.disp_start.y, p.disp_end.y+1):
            for dx in range(p.disp_start.x, p.disp_end.x+1):
                dut.dy.value = dy
                dut.dx.value = dx
                dut.frame_start.value = int(
                    dy == p.disp_start.y and dx == p.disp_start.x)
                dut.line_start.value = int(dx == p.disp_start.x)

                await ReadOnly()
                actual_paint = dut.paint.value

                in_window = (
                    p.win_start.y <= dy < p.win_end.y
                    and p.win_start.x <= dx+CLUT_LAT < p.win_end.x
                )
                exp_paint = Logic(1) if in_window else Logic(0)

                if actual_paint.is_resolvable:
                    assert actual_paint == exp_paint, (
                        f"paint: '{actual_paint}' is not expected '{exp_paint}'"
                        f"at ({dx}, {dy}) in frame={frame}!"
                    )

                await RisingEdge(dut.clk_pix)


@cocotb.test()  # pylint: disable=no-value-for-parameter
@cocotb.parametrize(p=[SCALE_0X0Y, SCALE_1X1Y, SCALE_2X2Y, SCALE_4X4Y, SCALE_3X5Y, FULL_DISP])
async def canv_disp_agu_addr(dut, p):
    """Test canvas display AGU pixel address."""
    cocotb.start_soon(Clock(dut.clk_pix, PIX_TIME, unit="ns").start())

    # reset
    dut.rst_pix.value = 0
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 1
    await RisingEdge(dut.clk_pix)
    dut.rst_pix.value = 0
    await RisingEdge(dut.clk_pix)

    # setup canvas
    dut.addr_base.value = p.addr_base
    dut.addr_shift.value = p.addr_shift
    dut.win_start.value = p.win_start.pack()
    dut.win_end.value = p.win_end.pack()
    dut.scale.value = p.scale.pack()

    for frame in range(2):  # test two frames
        for dy in range(p.disp_start.y, p.disp_end.y+1):
            for dx in range(p.disp_start.x, p.disp_end.x+1):
                dut.dy.value = dy
                dut.dx.value = dx
                dut.frame_start.value = int(
                    dy == p.disp_start.y and dx == p.disp_start.x)
                dut.line_start.value = int(dx == p.disp_start.x)

                await ReadOnly()
                addr = dut.addr.value
                pix_id = dut.pix_id.value

                scale_x = p.scale.x if p.scale.x > 0 else 1
                scale_y = p.scale.y if p.scale.y > 0 else 1

                vram_read = (
                    p.win_start.y <= dy < p.win_end.y
                    and p.win_start.x <= dx+ADDR_LAT < p.win_end.x
                )

                line_s = (p.win_end.x - p.win_start.x) // scale_x
                exp_addr_pix = (
                    ((dy - p.win_start.y) // scale_y) * line_s
                    + ((dx + ADDR_LAT - p.win_start.x) // scale_x)
                )

                exp_addr = p.addr_base + (exp_addr_pix >> p.addr_shift)

                pix_id_mask = (1 << p.addr_shift) - 1
                exp_pix_id = exp_addr_pix & pix_id_mask

                if vram_read and addr.is_resolvable and pix_id.is_resolvable:
                    assert int(addr) == exp_addr, (
                        f"addr: '{int(addr)}' is not expected '{exp_addr}'"
                        f"at ({dx}, {dy}) in frame={frame}!"
                    )
                    assert int(pix_id) == exp_pix_id, (
                        f"pix_id: '{int(pix_id)}' is not expected '{exp_pix_id}'"
                        f"at ({dx}, {dy}) in frame={frame}!"
                    )

                await RisingEdge(dut.clk_pix)
