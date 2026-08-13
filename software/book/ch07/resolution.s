# Isle.Computer - Print Resolutions (Chapter 7)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. This software is designed for chapter 7 hardware
#     temporary demo based on chapter 6 design.

.include "include/isle.inc"
.include "include/dev_display.inc"
.include "include/dev_earthrise.inc"

.section .text
.global _start

.equ BGRD_COLR, 1*1024 + 4*32 + 1*1;  # RGB555
.equ ISLE_COLR, 0x1D  # 0xXY Y=foreground colour and X=background
.equ TEXT_COLR, 0x14
.equ NUM_COLR,  0x15


_start:
    li sp, STACK_TOP  # stack grows down from here

    la a0, tm_cur  # load cursor address
    la a1, title  # load address of label in data section
    li a2, ISLE_COLR  # text colour
    call tm_print

    li t6, DEV_DISPLAY

    li t0, BGRD_COLR
    sw t0, DISP_BG_COLR(t6)  # set background colour

    # text mode
    li t0, 0  # transparent colour index - bitmap doesn't show through unless this is 0
    sw t0, TEXT_TIDX(t6)

    # # latency test bitmap
    # li t0, 2  # 4-colour bitmap
    # sw t0, CANV0_BPP(t6)
    # li t0, 0x00010001  # bitmap scale 1x
    # sw t0, CANV0_SCALE(t6)
    # li t0, 3  # transparent colour index
    # sw t0, CANV0_TIDX(t6)

    # crocus bitmap
    li t0, 4  # 16-colour bitmap
    sw t0, CANV0_BPP(t6)
    lw t0, CANV0_SCALE(t6)
    slli t0, t0, 1  # crocus is lores, so scale up 2x
    sw t0, CANV0_SCALE(t6)

    # test scrolling - we should animate this
    li t0, 0x00200020  # 32 pixels down, 32 pixels across
    sw t0, TEXT_WIN_START(t6)  # text display window start coordinates (y, x)

    # load dimensions from display device
    lw s1, DISP_DIMS_RO(t6)
    lw s2, BMAP_DIMS_RO(t6)
    lw s3, TEXT_DIMS_RO(t6)


    #
    # start Earthrise
    #
    li t6, DEV_EARTHRISE
    sw zero, ER_START_SB(t6)


    #
    # print display resolution
    #
    la a1, display  # load address of label in data section
    li a2, TEXT_COLR  # text colour
    call tm_print

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
    # print bitmap resolution
    #
    call tm_newline

    la a1, bitmap
    li a2, TEXT_COLR
    call tm_print

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

    #
    # print text mode resolution
    #
    call tm_newline

    la a1, textmode
    li a2, TEXT_COLR
    call tm_print

    la a0, num_str
    li t0, 0xFFFF
    and a1, s3, t0  # text mode x-resolution (lower 16 bits)
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
    srli a1, s3, 16  # text mode y-resolution (upper 16 bits)
    li a2, 0
    call int_strd
    mv a1, a0
    la a0, tm_cur
    li a2, NUM_COLR
    call tm_print

.L_scroll_loop:
    li a0, 10
    call frame_waitn
    li t0, 0xFFFF
    and t1, s3, t0  # text mode x-resolution (lower 16 bits)
    li t6, DEV_DISPLAY
    lw t0, TEXT_SCROLL_OFFSET(t6)
    sub t0, t0, t1
    lw t2, TRAM_DEPTH_RO(t6)
    bgez t0, .L_scroll_cont
    add t0, t0, t2  # add tram depth if scroll offset is less than zero
.L_scroll_cont:
    sw t0, TEXT_SCROLL_OFFSET(t6)
    j .L_scroll_loop


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

display:
    .asciz "Display: "

bitmap:
    .asciz "Bitmap:  "

textmode:
    .asciz "Text:    "
