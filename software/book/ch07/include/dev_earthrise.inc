# Isle.Computer - Earthrise Device (Chapter 7)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# Earthrise control and status (SB = strobe, RO = read only)
.equ ER_START_SB,         0x0100  # start Earthrise
.equ ER_RESET_SB,         0x0104  # reset (and stop) Earthrise
.equ ER_BUSY_RO,          0x0108  # Earthrise is busy drawing (remains high if awaiting enable)
.equ ER_CYCLE_COUNT_RO,   0x010C  # clock cycles the last drawing took to complete
.equ ER_PC_RO,            0x0110  # Earthrise program counter
.equ ER_INSTR_INVALID_RO, 0x0114  # invalid instruction flag has been raised

# Earthrise drawing control
.equ ER_BPP,            0x0200  # bits per pixel; controls colour depth: 1, 2, 4, or 8 bit
.equ ER_CANV_DIMS,      0x0204  # canvas dimension (bitmap pixels)
.equ ER_VRAM_ADDR_BASE, 0x0208  # base vram word address of canvas

# Earthrise erlist
.equ ER_CMDLIST_OFFSET, 0x8000


#
# Instruction Opcodes
#

# Coordinate Immediate
#   OR with coordinate/radius to create instruction
.equ ER_X0, 0x0000
.equ ER_Y0, 0x1000
.equ ER_X1, 0x2000
.equ ER_Y1, 0x3000
.equ ER_X2, 0x4000
.equ ER_Y2, 0x5000
.equ ER_X3, 0x6000
.equ ER_Y3, 0x7000
.equ ER_XT, 0x8000  # translate registers
.equ ER_YT, 0x9000
.equ ER_R0, 0x2000  # circle radius, shares register with x1

# colours
.equ ER_LCA, 0xC000
.equ ER_LCB, 0xC100
.equ ER_FCA, 0xC200
.equ ER_FCB, 0xC300
