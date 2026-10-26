# Isle.Computer - Hardware Test Helpers
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Test helpers for Isle cocotb hardware tests."""

from dataclasses import dataclass
import random

import cocotb
from cocotb.triggers import FallingEdge


@dataclass(frozen=True)
class Coords:
    """Isle packed coordinates (handles signed and unsigned)."""
    x: int
    y: int

    def pack(self, width: int) -> int:
        """Pack coords {y, x} matching Isle hardware."""
        lo, hi = -(1 << (width-1)), (1 << width) - 1
        if not lo <= self.x <= hi:
            raise ValueError(f"x-coord {self.x} doesn't fit in {width} bits")
        if not lo <= self.y <= hi:
            raise ValueError(f"y-coord {self.y} doesn't fit in {width} bits")
        mask = (1 << width) - 1
        return ((self.y & mask) << width) | (self.x & mask)


def assert_coord(dut, x, y):
    """Assert coordinate is correct."""
    coord_matches = (
        dut.disp_x.value == x and
        dut.disp_y.value == y
    )
    assert coord_matches, (
        f"({dut.disp_x.value.to_signed()},"
        f"{dut.disp_y.value.to_signed()})"
        f" is not ({x},{y})."
    )


def assert_pixel(dut, r, g, b, verbose=True):
    """Assert pixel colour is correct."""
    if verbose:
        log_pixel(dut)
    rgb_matches = (
        dut.disp_r.value == r and
        dut.disp_g.value == g and
        dut.disp_b.value == b
    )
    assert rgb_matches, (
        f"RGB({dut.disp_r.value.to_unsigned()},"
        f"{dut.disp_g.value.to_unsigned()},"
        f"{dut.disp_b.value.to_unsigned()})"
        f" is not RGB({r},{g},{b})."
    )


def log_pixel(dut):
    """Log pixel at current position"""
    r = dut.disp_r.value.to_unsigned()
    g = dut.disp_g.value.to_unsigned()
    b = dut.disp_b.value.to_unsigned()
    x = dut.disp_x.value.to_signed()
    y = dut.disp_y.value.to_signed()
    cocotb.log.info("RGB(%2d,%2d,%2d) at (%4d,%4d)", r, g, b, x, y)


def random_mem_model(addrw, dataw):
    """Return {addr: data} memory model with distinct non-zero values."""
    depth = 2**addrw
    nonzero_range = range(1, 2**dataw)  # range of possible non-zero data
    count = min(len(nonzero_range), depth)  # must exist and fit in memory
    addrs = random.sample(range(depth), count)
    data = random.sample(nonzero_range, count)
    return dict(zip(addrs, data))


def read_hex_file(file_path):
    """Read Verilog hex file with one value per line and // comment lines."""
    hex_data = []
    with open(file_path, 'r', encoding='utf8') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("//"):
                hex_data.append(int(line, base=16))
    return hex_data


async def read_mem(clk, addr, dout, addr_list, latency):
    """Read addr_list back-to-back and return data in the same order."""
    await FallingEdge(clk)
    data = []
    for i in range(len(addr_list) + latency-1):
        if i < len(addr_list):
            addr.value = addr_list[i]
        await FallingEdge(clk)
        if i >= latency-1:  # initial data arrives after latency cycles
            val = dout.value
            data.append(val.to_unsigned() if val.is_resolvable else str(val))
    return data
