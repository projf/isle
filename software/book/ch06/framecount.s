# Isle.Computer - Decimal Frame Counter (Chapter 6)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. This software is designed for chapter 6 hardware

.include "include/isle.inc"

.section .text
.global _start

.equ COLR, 0x05  # 0xXY Y=foreground colour and X=background


_start:
    li sp, STACK_TOP  # stack grows down from here
    li s11, 0  # frame counter

.L_cnt_loop:
    # convert integer counter to decimal string
    la a0, cnt_str  # load address of string to hold result
    mv a1, s11  # current counter value
    li a2, 1  # counter is unsigned
    call int_strd  # convert integer to string; returns string address in a0

    # print counter
    mv a1, a0  # move string address to a1 for printing
    la a0, tm_cur
    li a2, COLR
    call tm_print  # returns new cursor address
    sh zero, 0(a0)  # set cursor back to (0,0) by zeroing both bytes

    # increment counter
    addi s11, s11, 1

    # await next frame
    li a0, 1
    call frame_waitn
    j .L_cnt_loop


.section .data

.balign 4
cnt_str:  # decimal string - up to 12 bytes including sign and null
    .zero 12

.balign 2
tm_cur:  # text mode cursor
    .byte 0, 0
