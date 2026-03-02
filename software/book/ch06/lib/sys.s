# Isle.Computer - Asm System Library
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

.include "include/isle.inc"

.section .text
.global rand_pseudo
.global timer_reached
.global timer_wait


# rand_pseudo - return a pseudorandom number using lfsr
#   a0: start of range (unsigned)
#   a1: end of range (unsigned)
#   return: pseudorandom number
#
rand_pseudo:
    li t6, SYS_DEV

    # check range is positive: ensure a0 ≤ a1
    bleu a0, a1, 0f  # skip if already in correct order
    mv t0, a0
    mv a0, a1
    mv a1, t0
0:
    # determine range: a2 = a1 - a0 + 1
    sub  a2, a1, a0
    addi a2, a2, 1
    beqz a2, 2f  # branch if full range (a2 wraps to 0)

    # rejection threshold to remove bias
    neg t1, a2  # 2^32 - range
    remu t1, t1, a2  # threshold = 2^32 % range
1:
    # sample lfsr and check threshold
    lw t2, LFSR_32(t6)
    bltu t2, t1, 1b  # reject if bias value (try again)

    # create random number in range
    remu t2, t2, a2  # divide by range and keep remainder
    add  a0, t2, a0  # add start of range
    ret
2:
    # sample raw lfsr output for full range
    lw a0, LFSR_32(t6)
    ret


# timer_reached - return if timer has reached timestamp
#   a0: timestamp in milliseconds
#   return: 1 if reached; 0 otherwise
#
timer_reached:
    li t6, SYS_DEV
    lw t0, TIMER_0(t6)
    sltu t1, t0, a0  # check if t0<a0
    xori a0, t1, 1   # invert bit for a0≥t0
    ret


# timer_wait - busy wait for n milliseconds
#   a0: milliseconds to wait for
#   return: none
#
#   returns immediately when a0 is zero
#
timer_wait:
    beqz a0, 1f  # zero milliseconds?
    li t6, SYS_DEV
    lw t1, TIMER_0(t6)  # load base timestamp
    add t1, t1, a0  # set target timestamp
0:
    lw t0, TIMER_0(t6)  # load current timestamp
    blt t0, t1, 0b  # loop if not yet at target timestamp
1:
    ret
