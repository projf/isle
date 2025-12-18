# Isle.Computer - Hardware Test Helpers
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Test helpers for Isle cocotb hardware tests."""

import cocotb


def assert_coord(dut, x, y):
    """Assert coordinate is correct"""
    coord_matches = (
        dut.disp_x.value == x and
        dut.disp_y.value == y
    )

    assert coord_matches, (
        f"{dut.disp_x.value.to_signed()},"
        f"{dut.disp_y.value.to_signed()},"
        f" is not ({x},{y})."
    )


def assert_pixel(dut, r, g, b, verbose=True):
    """Assert pixel colour is correct"""
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
