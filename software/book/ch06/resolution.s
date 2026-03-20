# Isle.Computer - Print Resolutions (Chapter 6)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. This software is designed for chapter 6 hardware

.include "include/isle.inc"

.section .text
.global _start

.equ ISLE_COLR, 0x0D  # 0xXY Y=foreground colour and X=background
.equ NUM_COLR,  0x05


_start:
    li sp, STACK_TOP  # stack grows down from here

    la a0, tm_cur  # load cursor address
    la a1, title  # load address of label in data section
    li a2, ISLE_COLR  # text colour
    call tm_print

    li t6, GFX_DEV
    lw s1, DISP_DIMS(t6)
    lw s2, TEXT_DIMS(t6)

    #
    # print display resolution
    #
    la a0, num_str  # load address of string to hold result
    li t0, 0xFFFF  # mask for lower 16-bits
    and a1, s1, t0  # display x-resolution (lower 16 bits)
    li a2, 0  # coordinates are signed
    call int_strd  # convert integer to string; returns string address in a0
    mv a1, a0  # move string address to a1 for printing
    la a0, tm_cur
    li a2, NUM_COLR
    call tm_print  # returns new cursor address

    li a1, 'x'
    li a2, NUM_COLR
    call tm_put_next

    la a0, num_str
    srli a1, s1, 16  # display y-resolution (upper 16 bits)
    li a2, 0
    call int_strd
    mv a1, a0
    la a0, tm_cur
    li a2, NUM_COLR
    call tm_print

    call tm_cur_incx  # move one char to the right

    #
    # print text mode resolution
    #
    li a1, '('
    li a2, NUM_COLR
    call tm_put_next

    la a0, num_str
    li t0, 0xFFFF
    and a1, s2, t0  # text mode x-resolution (lower 16 bits)
    li a2, 0
    call int_strd
    mv a1, a0
    la a0, tm_cur
    li a2, NUM_COLR
    call tm_print

    li a1, 'x'
    li a2, NUM_COLR
    call tm_put_next

    la a0, num_str
    srli a1, s2, 16  # text mode y-resolution (upper 16 bits)
    li a2, 0
    call int_strd
    mv a1, a0
    la a0, tm_cur
    li a2, NUM_COLR
    call tm_print

    li a1, ')'
    li a2, NUM_COLR
    call tm_put_next

.exit:
    j .exit


.section .data

.balign 2
tm_cur:  # text mode cursor
    .byte 0, 0

.balign 4
num_str:  # decimal string - up to 12 bytes including sign and null
    .zero 12

.section .rodata
title:
    .asciz "Isle.Computer\n"
