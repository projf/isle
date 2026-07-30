# Isle.Computer - System Device (Chapter 7)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# hardware registers
.equ TIMER_0,     0x0300  # timer 0 (millisecond timer)
.equ TIMER_0_CLR, 0x0310  # strobe to reset timer
.equ LFSR_32,     0x0320  # 32-bit pseudo-random number generated via linear-feedback shift register
