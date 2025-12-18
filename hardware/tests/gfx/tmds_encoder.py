# Isle.Computer - TMDS Encoder (DVI) Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""TMDS Encoder (DVI) Test Bench (cocotb)"""

# NB. tmds_model.bias uses a static value for bias.
#     You can't have more than one test for TMDS per Python run.

import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

import tmds_model

TEST_INFO = 1  # display TMDS info for passing test cycles


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
async def tmds_random(dut):
    """Test 1000 random 8-bit pixel values."""
    cocotb.start_soon(Clock(dut.clk_pix, 1, units="ns").start())
    dut.ctrl_in.value = 0
    await reset_dut(dut)
    dut.de.value = 1

    for i in range(1001):  # 1000 tests (but 1001 values of i to account for DUT latency)
        pixel_dec = random.randrange(256)  # pixel value is in range 0-255
        dut.din.value = pixel_dec
        await RisingEdge(dut.clk_pix)

        if i >= 1:  # check DUT value against model one cycle later
            model_pixel_dec = pixel_dec_prev
            model_pixel_bin = tmds_model.bin_array_8(model_pixel_dec)
            model_tmds = tmds_model.tmds(model_pixel_bin, model_pixel_dec)
            model_bias = tmds_model.bias(model_tmds)
            model_val = ''.join(map(str, reversed(model_bias)))
            if TEST_INFO:
                cocotb.log.info("%4d: %02X - DUT: %s, Model: %s", \
                i, pixel_dec_prev, dut.tmds.value.binstr, model_val)
            assert dut.tmds.value.binstr == model_val, \
                f"DUT {dut.tmds.value.binstr} doesn't match model {model_val}!"

        pixel_dec_prev = pixel_dec  # save previous value for comparison in next iteration
