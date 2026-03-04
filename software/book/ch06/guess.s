# Isle.Computer - Guessing Game (Chapter 6)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. This software is designed for chapter 6 hardware only

.include "include/isle.inc"

.section .text
.global _start

# colours: 0xXY Y=foreground colour and X=background
.equ TEXT_COLR_TITLE, 0x0D
.equ TEXT_COLR_IN,  0x05
.equ TEXT_COLR_OUT, 0x04
.equ TEXT_CUR_COLR, 0x01
.equ TEXT_CUR_CHAR, 0x2588  # U+2588 - Full block
.equ STR_LEN_BYTES, 16  # maximum answer length in bytes (each utf8 char is 1-4 bytes)

_start:
    li sp, STACK_TOP  # stack grows down from here
    la a0, tm_cur  # load cursor address
    call tm_clr  # clear screen
    la a1, intro  # load address of label in data section
    li a2, TEXT_COLR_TITLE  # text colour
    call tm_print
    li s1, 0  # initialise secret number (0 signals not yet chosen)

.L_read:
    la a0, tm_cur
    la a1, guess
    li a2, TEXT_COLR_TITLE
    call tm_print

    # read a line of text from UART
    la a1, str_buf  # in data section; ensure its length is enough for a2
    li a2, STR_LEN_BYTES  # length of str_buf including null terminator
    li a3, TEXT_COLR_IN
    li a4, TEXT_CUR_CHAR
    li a5, TEXT_CUR_COLR
    call read_ln  # returns cursor address in a0

    # wait until after user input to choose secret number (timing entropy)
    bnez s1, .L_check
    li a0, 1
    li a1, 100
    call rand_pseudo
    mv s1, a0  # save secret number

.L_check:
    la a0, str_buf  # load address of label in data section
    call strd_int
    blt a0, s1, .L_too_low
    bgt a0, s1, .L_too_high

    la a0, tm_cur
    la a1, correct
    li a2, TEXT_COLR_TITLE
    call tm_print
    call tm_clr_line

    li a0, 4000  # wait 4 seconds after correct answer
    call timer_wait
    j _start

.L_too_low:
    la a0, tm_cur
    la a1, too_low
    li a2, TEXT_COLR_OUT
    call tm_print
    call tm_clr_line
    call tm_newline
    j .L_read
.L_too_high:
    la a0, tm_cur
    la a1, too_high
    li a2, TEXT_COLR_OUT
    call tm_print
    call tm_clr_line
    call tm_newline
    j .L_read


.section .data

.balign 2
tm_cur:  # text mode cursor
    .byte 0, 0

.balign 4
str_buf:
    .zero STR_LEN_BYTES

.section .rodata

intro:
    .asciz "I'm thinking of a number between 1-100.\n"

guess:
    .asciz "What's your guess? "

correct:
    .asciz "Correct!"

too_low:
    .asciz "Too low."

too_high:
    .asciz "Too high."
