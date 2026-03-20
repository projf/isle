# Isle.Computer - Asm Graphics Library
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

.include "include/isle.inc"

.section .text
.global frame_waitn


# frame_waitn - busy wait for n frame start signals
#   a0: frame count (starts) to wait for
#   return: none
#
#   returns immediately when a0 is zero
#
frame_waitn:
    beqz a0, 1f  # zero frames?
    li   t6, GFX_DEV  # hwreg base addr
0:
    lw   t0, FRAME_FLAG(t6)  # load frame flag
    beqz t0, 0b  # loop if flag not set
    sw   zero, FRAME_FLAG_CLR(t6)  # clear frame flag (strobe)

    addi a0, a0, -1  # decrement remaining frame count
    bnez a0, 0b  # loop if frames remain
1:
    ret
