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

# test display 16x8 pixels
X_MIN = -7
X_MAX = 15
Y_MIN = -2
Y_MAX = 7

# latencies (must match canv_disp_agu.mk)
CLUT_LAT = 1
VRAM_LAT = 3

@dataclass(frozen=True)
class CanvasParams:
    """Hold canvas parameters."""
    addr_base: int
    addr_shift: int
    win_start: Coords
    win_end: Coords
    scale: Coords

# test params
SCALE_0X0Y = CanvasParams (
    addr_base = 0x0,
    addr_shift = 3,  # 16 colour
    win_start = Coords(x=0, y=0),
    win_end = Coords(x=X_MAX+1, y=Y_MAX+1),
    scale = Coords(x=0, y=0),  # hardware should treat as 1x
)

SCALE_1X1Y = CanvasParams (
    addr_base = 0xC03,
    addr_shift = 5,  # 2 colour
    win_start = Coords(x=2, y=1),
    win_end = Coords(x=X_MAX+1, y=Y_MAX+1),
    scale = Coords(x=1, y=1),
)

SCALE_2X2Y = CanvasParams (
    addr_base = 0x201,
    addr_shift = 4,  # 4 colour
    win_start = Coords(x=1, y=1),
    win_end = Coords(x=X_MAX, y=Y_MAX),
    scale = Coords(x=2, y=2),
)

SCALE_4X4Y = CanvasParams (
    addr_base = 0x2000,
    addr_shift = 3,  # 16 colour
    win_start = Coords(x=0, y=0),
    win_end = Coords(x=X_MAX+1, y=Y_MAX+1),
    scale = Coords(x=4, y=4),
)

SCALE_3X5Y = CanvasParams (
    addr_base = 0x1FFF,
    addr_shift = 2,  # 256 colour
    win_start = Coords(x=0, y=0),
    win_end = Coords(x=X_MAX+1, y=Y_MAX+1),
    scale = Coords(x=3, y=5),
)


@cocotb.test()  # pylint: disable=no-value-for-parameter
@cocotb.parametrize(params=[SCALE_0X0Y, SCALE_1X1Y, SCALE_2X2Y, SCALE_4X4Y, SCALE_3X5Y])
async def canv_disp_agu_paint(dut, params):
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
    dut.addr_base.value = params.addr_base
    dut.addr_shift.value = params.addr_shift
    dut.win_start.value = params.win_start.pack()
    dut.win_end.value = params.win_end.pack()
    dut.scale.value = params.scale.pack()

    for frame in range(2):  # test two frames in a row
        for dy in range(Y_MIN, Y_MAX+1):
            for dx in range(X_MIN, X_MAX+1):
                dut.dy.value = dy
                dut.dx.value = dx
                dut.frame_start.value = 1 if dy == Y_MIN and dx == X_MIN else 0
                dut.line_start.value = 1 if dx == X_MIN else 0

                await ReadOnly()
                actual_paint = dut.paint.value

                in_window = (params.win_start.y <= dy < params.win_end.y
                    and params.win_start.x <= dx+CLUT_LAT < params.win_end.x)
                expected_paint = Logic(1) if in_window else Logic(0)

                if actual_paint.is_resolvable:
                    assert actual_paint == expected_paint, \
                        f"paint: '{actual_paint}' is not expected '{expected_paint}' at ({dx}, {dy}) in frame={frame}!"

                await RisingEdge(dut.clk_pix)


@cocotb.test()  # pylint: disable=no-value-for-parameter
@cocotb.parametrize(params=[SCALE_0X0Y, SCALE_1X1Y, SCALE_2X2Y, SCALE_4X4Y, SCALE_3X5Y])
async def canv_disp_agu_addr(dut, params):
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
    dut.addr_base.value = params.addr_base
    dut.addr_shift.value = params.addr_shift
    dut.win_start.value = params.win_start.pack()
    dut.win_end.value = params.win_end.pack()
    dut.scale.value = params.scale.pack()

    for frame in range(2):  # test two frames
        for dy in range(Y_MIN, Y_MAX+1):
            for dx in range(X_MIN, X_MAX+1):
                dut.dy.value = dy
                dut.dx.value = dx
                dut.frame_start.value = 1 if dy == Y_MIN and dx == X_MIN else 0
                dut.line_start.value = 1 if dx == X_MIN else 0

                await ReadOnly()
                actual_addr_pix = dut.addr_pix.value
                actual_addr = dut.addr.value
                actual_pix_id = dut.pix_id.value

                scale_x = params.scale.x if params.scale.x > 0 else 1
                scale_y = params.scale.y if params.scale.y > 0 else 1

                ADDR_LAT = CLUT_LAT + VRAM_LAT
                vram_read = (params.win_start.y <= dy < params.win_end.y
                    and params.win_start.x <= dx+ADDR_LAT < params.win_end.x)

                line_s = (params.win_end.x - params.win_start.x) // scale_x
                expected_addr_pix = ((dy - params.win_start.y) // scale_y) * line_s \
                    + ((dx + ADDR_LAT - params.win_start.x) // scale_x)

                expected_addr = params.addr_base + (expected_addr_pix >> params.addr_shift)

                pix_id_mask = (1 << params.addr_shift) - 1
                expected_pix_id = expected_addr_pix & pix_id_mask

                if vram_read and actual_addr.is_resolvable and actual_pix_id.is_resolvable:
                    assert int(actual_addr) == expected_addr, \
                        f"addr: '{int(actual_addr)}' is not expected '{expected_addr}' at ({dx}, {dy}) in frame={frame}!"
                    assert int(actual_pix_id) == expected_pix_id, \
                        f"pix_id: '{int(actual_pix_id)}' is not expected '{expected_pix_id}' at ({dx}, {dy}) in frame={frame}!"

                await RisingEdge(dut.clk_pix)
