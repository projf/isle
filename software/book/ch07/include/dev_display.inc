# Isle.Computer - Display Device (Chapter 7)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

#
# read-only registers
#

.equ DISP_DIMS_RO,      0x0100  # display native dimensions in pixels
.equ BMAP_DIMS_RO,      0x0104  # display bitmap dimensions in pixels
.equ TEXT_DIMS_RO,      0x0108  # display textmode dimensions in half-width chars
.equ FRAME_FLAG_RO,     0x010C  # signals start of new display frame
.equ TRAM_DEPTH_RO,     0x0110  # tram depth in half-width characters


#
# strobe registers
#

.equ FRAME_FLAG_SB,     0x0180  # clear frame flag


#
# read-write registers
#

# DISP_VISIBLE - 16-bit value
# - 1st byte is visibility (bit0=textmode, bit1=canvas0)
# - 2nd byte transparency (bit8=textmode, bit9=canvas0)

.equ DISP_VISIBLE,         0x0200  # graphics visibility and transparency options
.equ DISP_BG_COLR,         0x0204  # background colour RGB555

.equ TEXT_WIN_START,       0x0208  # text display window start coordinates (y, x)
.equ TEXT_WIN_END,         0x020C  # text display window end coordinates (y, x)
.equ TEXT_SCALE,           0x0210  # display scaling (scale_y, scale_x)
.equ TEXT_PAL,             0x0214  # textmode palette offset
.equ TEXT_TIDX,            0x0218  # text transparent colour index
.equ TEXT_SCROLL_OFFSET,   0x021C  # text scroll offset

.equ CANV0_WIN_START,      0x0220  # canvas display window start coordinates (y, x)
.equ CANV0_WIN_END,        0x0224  # canvas display window end coordinates (y, x)
.equ CANV0_SCALE,          0x0228  # canvas display scaling (scale_y, scale_x)
.equ CANV0_PAL,            0x022C  # canvas palette offset
.equ CANV0_TIDX,           0x0230  # transparent colour index
.equ CANV0_DIMS,           0x0234  # dimensions (height, width)
.equ CANV0_VRAM_ADDR_BASE, 0x0238  # base vram word address
.equ CANV0_BPP,            0x023C  # bits per pixel (1,2,4,8)
.equ CANV0_SCROLL_COORD,   0x0240  # canvas scroll coordinate (must match CANV0_SCROLL_OFFSET)
.equ CANV0_SCROLL_OFFSET,  0x0244  # pixel offset of canvas scroll line


# todo: need to decide where to start CANV1 - but want it to be a round address
