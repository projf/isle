# Isle.Computer - VRAM Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""VRAM Test Bench (cocotb)"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from tests.helpers import zero_vram

# clock frequencies
SYS_TIME = 40  # 40 ns is 25 MHz
PIX_TIME = 20  # 20 ns is 50 MHz

# vram write data for sys port word test
tdat_addr_in = [0x02, 0x1F, 0x00, 0x15, 0x0A]
tdat_din     = [0x6,  0x0,  0xF,  0x9,  0x1 ]

# vram expected data for sys port word test - 1 cycle latency
# first expected data is from the address used to write the last item (above)
expt_addr_sys = [0x02, 0x1F, 0x00, 0x15, 0x0A, 0x00]
expt_data_sys = [0x1,  0x6,  0x0,  0xF,  0x9,  0x1 ]

# vram write data for sys port mask test
tdat_mask_addr_in = [0x02, 0x02, 0x00, 0x00,        0x02]
tdat_mask_din     = [0x1,  0x4,  0xC0, 0x99999999,  0x008000000]
tdat_mask_wmask   = [0x1,  0x4,  0xF0, 0xF0000000,  0x00C000000]

# vram expected data for sys port mask test - 1 cycle latency
# first expected data is from the address used to write the last item (above)
expt_mask_addr_sys = [0x02,        0x00,        0x01,       0x02,       0x00       ]
expt_mask_data_sys = [0x008000005, 0x008000005, 0x900000C0, 0x00000000, 0x008000005]

# vram expected data for disp port - 2 cycle latency
expt_addr_disp = [0x02, 0x1F,  0x00, 0x01, 0x01]
expt_data_disp = ["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
                  "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
                  0x008000005, 0x00000000, 0x900000C0]


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def sys_port_word(dut):
    """Test vram sys port with word data."""
    cocotb.start_soon(Clock(dut.clk_sys, SYS_TIME, unit="ns").start())
    await zero_vram(dut)  # zeroed memory matches FPGA

    # write data
    for addr, data in zip(tdat_addr_in, tdat_din, strict=True):
        dut.wmask_sys.value = 0xFFFFFFFF
        dut.addr_sys.value = addr
        dut.din_sys.value = data
        await RisingEdge(dut.clk_sys)

    dut.wmask_sys.value = 0x00000000
    dut.re_sys.value = 1
    await RisingEdge(dut.clk_sys)

    # read data back
    for i, (addr, data_expected) in enumerate(zip(expt_addr_sys, expt_data_sys, strict=True)):
        dut.addr_sys.value = addr
        await RisingEdge(dut.clk_sys)

        if dut.dout_sys.value.is_resolvable:
            sys_data = dut.dout_sys.value.to_unsigned()
        else:
            sys_data = dut.dout_sys.value

        assert sys_data == data_expected, \
            f"DUT i={i} {sys_data} doesn't match expected {data_expected} at address 0x{addr:X}!"

    dut.re_sys.value = 0
    await RisingEdge(dut.clk_sys)


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def sys_port_mask(dut):
    """Test vram sys port with masked data."""
    cocotb.start_soon(Clock(dut.clk_sys, SYS_TIME, unit="ns").start())
    await zero_vram(dut)  # zeroed memory matches FPGA

    # write data
    for addr, data, wmask in zip(tdat_mask_addr_in, tdat_mask_din, tdat_mask_wmask, strict=True):
        dut.wmask_sys.value = wmask
        dut.addr_sys.value = addr
        dut.din_sys.value = data
        await RisingEdge(dut.clk_sys)

    dut.wmask_sys.value = 0x00000000
    dut.re_sys.value = 1
    await RisingEdge(dut.clk_sys)

    # read data back
    expt_sys_data = zip(expt_mask_addr_sys, expt_mask_data_sys, strict=True)
    for i, (addr, data_expected) in enumerate(expt_sys_data):
        dut.addr_sys.value = addr
        await RisingEdge(dut.clk_sys)

        if dut.dout_sys.value.is_resolvable:
            sys_data = dut.dout_sys.value.to_unsigned()
        else:
            sys_data = dut.dout_sys.value

        assert sys_data == data_expected, \
            f"DUT i={i} {sys_data} doesn't match expected {data_expected} at address 0x{addr:X}!"

    dut.re_sys.value = 0
    await RisingEdge(dut.clk_sys)


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def disp_port(dut):
    """Test vram disp port."""
    cocotb.start_soon(Clock(dut.clk_pix, PIX_TIME, unit="ns").start())

    # read data written via system port
    expt_disp_data = zip(expt_addr_disp, expt_data_disp, strict=True)
    for i, (addr, data_expected) in enumerate(expt_disp_data):
        dut.addr_disp.value = addr
        await RisingEdge(dut.clk_pix)

        if dut.dout_disp.value.is_resolvable:
            disp_data = dut.dout_disp.value.to_unsigned()
        else:
            disp_data = dut.dout_disp.value

        assert disp_data == data_expected, \
            f"DUT i={i} {disp_data} doesn't match expected {data_expected} at address 0x{addr:X}!"
