# Isle.Computer - CLUT Test Bench
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

"""CLUT Test Bench (cocotb)"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

# clock frequencies
PIX_TIME = 13.89  # 72 MHz
SYS_TIME  = 40    # 25 MHz

# CLUT test data (for writing)
test_addr_in = [0x2, 0xF, 0x0, 0x5, 0xA]
test_din = [0xA, 0x0, 0x7, 0x9, 0x1]

# CLUT expected data for sys port - 1 cycle latency
# first expected data is from the address used to write the last item (above)
test_addr_sys = [0x2, 0xF, 0x0, 0x5, 0xA, 0x0]
test_data_sys = [0x1, 0xA, 0x0, 0x7, 0x9, 0x1]

# CLUT expected data for disp port - 2 cycle latency
test_addr_disp = [0x2, 0xF, 0x0, 0x5, 0xA, 0x0, 0x0]
test_data_disp = ["xxxxxxxxxxxx", "xxxxxxxxxxxx", 0xA, 0x0, 0x7, 0x9, 0x1]


async def zero_memory(dut):
    """Zero CLUT to match hardware behaviour for block ram."""

    for i in range(2**dut.ADDRW.value):
        dut.we_sys.value = 1
        dut.addr_sys.value = i
        dut.din_sys.value = 0
        await RisingEdge(dut.clk_sys)

    dut.we_sys.value = 0
    await RisingEdge(dut.clk_sys)

@cocotb.test()  # pylint: disable=no-value-for-parameter
async def sys_port(dut):
    """Test CLUT sys port."""

    cocotb.start_soon(Clock(dut.clk_sys, SYS_TIME, units="ns").start())
    await zero_memory(dut)  # matches hardware behaviour

    # write data
    for addr, data in zip(test_addr_in, test_din):
        dut.we_sys.value = 1
        dut.addr_sys.value = addr
        dut.din_sys.value = data
        await RisingEdge(dut.clk_sys)

    dut.we_sys.value = 0
    await RisingEdge(dut.clk_sys)

    # read data back
    for i, (addr, data_expected) in enumerate(zip(test_addr_sys, test_data_sys)):
        dut.addr_sys.value = addr
        await RisingEdge(dut.clk_sys)

        if dut.dout_sys.value.is_resolvable:
            sys_data = dut.dout_sys.value.integer
        else:
            sys_data = dut.dout_sys.value

        assert sys_data == data_expected, \
            f"DUT i={i} {sys_data} doesn't match expected {data_expected}!"


@cocotb.test()  # pylint: disable=no-value-for-parameter
async def disp_port(dut):
    """Test CLUT disp port."""
    cocotb.start_soon(Clock(dut.clk_pix, PIX_TIME, units="ns").start())

    # read data written via system port
    for i, (addr, data_expected) in enumerate(zip(test_addr_disp, test_data_disp)):
        dut.addr_disp.value = addr
        await RisingEdge(dut.clk_pix)

        if dut.dout_disp.value.is_resolvable:
            disp_data = dut.dout_disp.value.integer
        else:
            disp_data = dut.dout_disp.value

        assert disp_data == data_expected, \
            f"DUT i={i} {disp_data} doesn't match expected {data_expected}!"
