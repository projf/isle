# Isle.Computer - Isle Include (Chapter 7)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# 24-bit Memory Map

.equ STACK_TOP,    0xFFFFF0  # stack grows down from here 0xFF_FFFF...
.equ SYSRAM_BASE,  0x800000  # system memory base address
.equ DEV_SYS_ADDR, 0x600000  # system (fixed) device
.equ VRAM_BASE,    0x400000  # vram base address
.equ TRAM_BASE,    0x500000  # tram base address
.equ CLUT_BASE,    0x580000  # clut base address

# temporary device addresses
.equ DEV_SYS,       0x600000  # system device
.equ DEV_DISPLAY,   0x610000  # display device
.equ DEV_UART,      0x620000  # uart device
.equ DEV_EARTHRISE, 0x630000  # uart device
