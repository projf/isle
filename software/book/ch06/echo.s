# Isle.Computer - Echo (Chapter 6)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

.include "include/isle.inc"

.section .text
.global _start

# colours: 0xXY Y=foreground colour and X=background
.equ TEXT_COLR_TITLE, 0x0D
.equ TEXT_COLR_IN,  0x05
.equ TEXT_COLR_OUT, 0x04
.equ TEXT_CUR_COLR, 0x01
.equ TEXT_CUR_CHAR, 0x2588  # U+2588 - Full block
.equ STR_LEN_BYTES, 128  # maximum string length in bytes (each utf8 char is 1-4 bytes)

_start:
    li sp, STACK_TOP  # stack grows down from here
    la a0, tm_cur  # load cursor address
    la a1, title  # load address of label in data section
    li a2, TEXT_COLR_TITLE  # text colour
    call tm_print

    la a0, tm_cur  # load cursor address (calls in loop return cursor)
.L_read:
    # read a line of text from UART
    la a1, str_buf
    li a2, STR_LEN_BYTES  # length of str_buf including null terminator
    li a3, TEXT_COLR_IN
    li a4, TEXT_CUR_CHAR
    li a5, TEXT_CUR_COLR
    call read_ln  # returns cursor address in a0

    la a1, str_buf
    li a2, TEXT_COLR_OUT
    call tm_print

    call tm_newline
    j .L_read  # loop forever


.section .data

.balign 2
tm_cur:  # text mode cursor
    .byte 0, 0

.balign 4
str_buf:
    .zero STR_LEN_BYTES

.section .rodata
title:
    .asciz "▁▂▃▄▅▆▇█ Isle.Computer █▇▆▅▄▃▂▁\n"
