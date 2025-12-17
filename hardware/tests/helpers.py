# Isle.Computer - Hardware Test Helpers
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""Test helpers for Isle cocotb hardware tests."""

import cocotb


def assert_coord(dut, x, y):
    """Assert coordinate is correct"""
    assert dut.disp_x.value == x and dut.disp_y.value == y, \
        f"({dut.disp_x.value.signed_integer},{dut.disp_y.value.signed_integer}) is not ({x},{y})."


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
        f"RGB({dut.disp_r.value.integer},"
        f"{dut.disp_g.value.integer},"
        f"{dut.disp_b.value.integer}) "
        f"is not RGB({r},{g},{b})."
    )


def log_pixel(dut):
    """Log pixel at current position"""
    r = dut.disp_r.value.integer
    g = dut.disp_g.value.integer
    b = dut.disp_b.value.integer
    x = dut.disp_x.value.signed_integer
    y = dut.disp_y.value.signed_integer

    cocotb.log.info("RGB(%2d,%2d,%2d) at (%4d,%4d)", r, g, b, x, y)
