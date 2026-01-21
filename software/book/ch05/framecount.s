# Isle.Computer - Hex Frame Counter (Chapter 5)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. This software is designed for chapter 5 hardware only

.equ TRAM_BASE,      0x4000  # text mode ram (tram) base address
.equ HWREG_BASE,     0xC000  # hardware reg base address
.equ FRAME_FLAG,     0x0110  # signals start of new frame (offset to HWREG_BASE)
.equ FRAME_FLAG_CLR, 0x0114  # clear frame flag (offset to HWREG_BASE)

.equ TEXT_COLR, 0x0D000000  # 0xXY000000 Y=foreground colour and X=background


.section .text
.global _start

_start:
    li sp, 0xC000  # stack grows down from here
    li s11, TEXT_COLR

.L_cnt_loop:
    li s1, TRAM_BASE  # needs to be in the loop to reset it after L_str_loop
    # load integer counter from memory and convert to hex string
    la a0, cnt_str  # load address of string to hold result
    la t5, cnt  # load address of counter in memory
    lw a1, 0(t5)  # load integer value of counter
    call int_strx  # convert integer to string; returns string address in a0

    # print hex number
.L_str_loop:
    lbu t2, 0(a0)  # load char
    beqz t2, .L_next_frame  # check for string end
    or t0, s11, t2  # combine text colour with code point
    sw t0, 0(s1)  # store char in tram
    addi a0, a0, 1  # next char
    addi s1, s1, 4  # next tram address
    j .L_str_loop

.L_next_frame:
    # increment counter in memory
    la t5, cnt
    lw t0, 0(t5)
    addi t0, t0, 1
    sw t0, 0(t5)

    # wait for next frame
    li a0, 1
    call frame_waitn
    j .L_cnt_loop


# frame_waitn - wait for n frame start signals
#   a0: frame count (starts) to wait for
#   return: none
#
#   returns immediately when 'a0' is zero
#
frame_waitn:
    beqz a0, 1f  # don't wait if 'a0' is zero
    li   t6, HWREG_BASE  # hwreg base addr
0:
    lw   t0, FRAME_FLAG(t6)  # load frame flag
    beqz t0, 0b  # loop if flag not set
    sw   zero, FRAME_FLAG_CLR(t6)  # clear frame flag (strobe)

    addi a0, a0, -1  # decrement remaining frame count
    bnez a0, 0b  # loop if frames remain
1:
    ret


# int_strx - integer to hexadecimal string
#   a0: address to hold decoded string (8 bytes + null termination)
#   a1: integer
#   return: address of string start
#
int_strx:
    li   t5, 0x3A      # threshold for converting to A-F
    addi t6, a0, 8     # start with least significant digit and work back
    sb   zero, 0(t6)   # store null-termination

.L_nib_loop:
    addi t6, t6, -1    # decrement string address
    andi t0, a1, 0xF   # AND out first nibble
    addi t0, t0, 0x30  # add U+0030 offset
    blt  t0, t5, 0f    # jump to loop end if number
    addi t0, t0, 7     # add 0x7 for A-F
0:
    sb   t0, 0(t6)     # write Unicode code point to string
    srli a1, a1, 4     # shift across next nibble
    bne  t6, a0, .L_nib_loop
    ret


.section .data

.balign 4
cnt:
    .word 0
cnt_str:  # 9 bytes
    .byte 0, 0, 0, 0, 0, 0, 0, 0, 0
