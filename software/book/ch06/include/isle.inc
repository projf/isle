# Isle.Computer - Isle Include (Chapter 6)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# 16 KiB of system memory 0x8000 - 0xBFFC
.equ STACK_TOP, 0xC000  # stack grows down from below devices 0xBFFC etc.

# 64 KiB Memory Map
.equ CLUT_BASE,  0x0000  # colour lookup table base address
.equ TRAM_BASE,  0x4000  # text mode ram (tram) base address
.equ SYS_DEV,    0xC000  # system device
.equ GFX_DEV,    0xD000  # graphics device
.equ UART_DEV,   0xE000  # uart device

# system device
.equ TIMER_0,     0x0300
.equ TIMER_0_CLR, 0x0310
.equ LFSR_32,     0x0320

# graphics device
.equ DISP_DIMS,      0x0100  # display dimensions in pixels (y, x)
.equ FRAME_FLAG,     0x0110  # signals start of new frame (offset to HWREG_BASE)
.equ FRAME_FLAG_CLR, 0x0114  # clear frame flag (offset to HWREG_BASE)
.equ TEXT_DIMS,      0x0200  # textmode display dimensions in chars (height, width)
.equ TRAM_DEPTH,     0x0204  # depth of tram in chars (words)

# uart device (rx is to Isle)
.equ UART_RX_EN,  0x0100  # enable uart rx into fifo
.equ UART_RX_DAT, 0x0104  # uart rx data via fifo
.equ UART_RX_DEP, 0x0108  # uart rx fifo depth
.equ UART_RX_LEN, 0x010C  # uart rx fifo length (items)
