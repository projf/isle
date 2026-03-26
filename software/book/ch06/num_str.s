# Isle.Computer - Number Sting Conversion (Chapter 6)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. This software is designed for chapter 6 hardware

.include "include/isle.inc"

.section .text
.global _start

.equ COLR, 0x0D  # 0xXY Y=foreground colour and X=background
.equ DEC_COLR, 0x03
.equ HEX_COLR, 0x05

_start:
    li sp, STACK_TOP  # stack grows down from here
    la a0, tm_cur  # load cursor address
    la a1, title  # load address of label in data section
    li a2, COLR  # text colour
    call tm_print

.L_decimal:
    la a0, str_d0  # decimal string to convert
    li a1, 0  # signed
    call dec_test

    la a0, str_d1
    li a1, 1  # unsigned
    call dec_test

    la a0, str_d2
    li a1, 0
    call dec_test

    la a0, str_d3
    li a1, 0
    call dec_test

    la a0, str_d3
    li a1, 1  # unsigned
    call dec_test

    la a0, str_d4
    li a1, 0
    call dec_test

    la a0, str_d5
    li a1, 0
    call dec_test

    la a0, str_d6
    li a1, 0
    call dec_test

.L_hexadecimal:
    la a0, str_h0  # hexadecimal string to convert
    call hex_test

    la a0, str_h1
    call hex_test

    la a0, str_h2
    call hex_test

    la a0, str_h3
    call hex_test

    la a0, str_h4
    call hex_test

    la a0, str_h5
    call hex_test

    la a0, str_h6
    call hex_test

.exit:
    j .exit


# decimal string test
dec_test:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   s1,  8(sp)

    mv s1, a1  # signed/unsigned
    call strd_int  # returns integer form of string (a0)
    mv a1, a0  # number to print (convert to decimal)
    la a0, d_str  # load address to hold decoded string
    mv a2, s1  # signed?
    call int_strd  # returns address of string (a0)

    mv a1, a0  # move string address to a1 for printing
    la a0, tm_cur
    li a2, DEC_COLR
    call tm_print
    call tm_clr_line
    call tm_newline

    lw   s1,  8(sp)
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret

hex_test:
    addi sp, sp, -16
    sw   ra, 12(sp)

    call strx_int  # returns integer form of string (a0)
    mv a1, a0  # number to print (convert to hexadecimal)
    la a0, h_str  # load address to hold decoded string
    call int_strx  # returns address of string (a0)

    mv a1, a0  # move string address to a1 for printing
    la a0, tm_cur
    li a2, HEX_COLR
    call tm_print
    call tm_clr_line
    call tm_newline

    lw   ra, 12(sp)
    addi sp, sp, 16
    ret


.section .data
.balign 2
tm_cur:  # text mode cursor
    .byte 0, 0

d_str:  # decimal string - up to 12 bytes including sign and null terminator
    .zero 12

h_str:  # hext string - 8 bytes + null terminator
    .zero 9


.section .rodata
title:
    .asciz "Number String Tests\n"

# test strings
str_d0:
    .asciz "0"
str_d1:
    .asciz "7"
str_d2:
    .asciz "-1"
str_d3:
    .asciz "4294967295"  # 2^32-1
str_d4:
    .asciz "a"  # invalid decimal
str_d5:
    .asciz "4294967299"  # overflow
str_d6:
    .asciz "123a5"  # stop at non-decimal

str_h0:
    .asciz "0"
str_h1:
    .asciz "A"
str_h2:
    .asciz "FFF"
str_h3:
    .asciz "89ABCDef"
str_h4:
    .asciz "?"  # invalid hexadecimal
str_h5:
    .asciz "A987654321"  # overflow
str_h6:
    .asciz "123g5"  # stop at non-hexadecimal
