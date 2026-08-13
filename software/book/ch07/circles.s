# Isle.Computer - Circles (Chapter 7)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

.include "include/isle.inc"
.include "include/dev_display.inc"
.include "include/dev_earthrise.inc"
.include "include/dev_uart.inc"

# text colour (index to clut)
.equ TEXT_COLR, 0x05  # 0xXY Y=foreground colour and X=background

# circle properties
.equ CIRCLE_RATE,  10  # frames between drawing circles
.equ CIRCLE_R_MIN,  2  # minimum circle ring radius
.equ CIRCLE_R_MAX, 12  # maximum circle ring radius

# scroll properties
.equ SCROLL_X, -1  # horizontal scroll each frame (-1 scrolls right)
.equ SCROLL_Y,  1  # vertical scroll each frame (+1 scrolls up)

# Earthrise command list offsets - must match drawings/circle-rings.mem
.equ XT_ADDR,       0x02
.equ YT_ADDR,       0x04
.equ RING0_R0_ADDR, 0x0C
.equ RING1_R0_ADDR, 0x12
.equ RING2_R0_ADDR, 0x18
.equ RING3_R0_ADDR, 0x1C


.section .text
.global _start

_start:
    li sp, STACK_TOP  # stack grows down from here

    li s1, DEV_DISPLAY
    li s2, DEV_EARTHRISE
    li s3, ER_CMDLIST_OFFSET
    add s3, s3, s2  # get command list by adding earthrise device address

    # print instruction message
    la a0, tm_cur  # text mode cursor address
    la a1, message
    li a2, TEXT_COLR
    call tm_print  # returns new cursor address, but we don't need it here

    # wait for a key press before continuing
    li t0, DEV_UART
    li t1, 1
    sw t1, UART_RX_EN(t0)  # enable UART RX

    call uart_rx_byte  # wait for the user to press a key

    la a0, tm_cur
    call tm_clr  # clear text mode (hide instructions)

    li t0, DEV_UART
    sw zero, UART_RX_EN(t0)  # disable UART RX

    # get canvas dimensions
    lw t0, CANV0_DIMS(s1)
    li t1, 0x0000FFFF
    and s7, t0, t1  # canvas x-dimension
    srli t0, t0, 16
    and s8, t0, t1  # canvas y-dimension


.L_draw_loop:
    li s6, 0  # circle draw rate counter

    # choose random x-coordinate
    li a0, 0
    addi a1, s7, -1  # canvas x-dimension less 1
    call rand_pseudo
    li t5, ER_XT   # x-translation opcode
    or t0, a0, t5  # combine random coordinate with opcode
    sh t0, XT_ADDR(s3)  # store xt in cmd list

    # choose random y-coordinate
    li a0, 0
    addi a1, s8, -1  # canvas y-dimension less 1
    call rand_pseudo
    li t5, ER_YT   # y-translation opcode
    or t0, a0, t5  # combine random coordinate with opcode
    sh t0, YT_ADDR(s3)  # store yt in cmd list

    # choose random radius
    li a0, CIRCLE_R_MIN
    li a1, CIRCLE_R_MAX
    call rand_pseudo
    li t5, ER_R0   # radius opcode
    or t0, a0, t5  # combine radius with opcode
    sh t0, RING3_R0_ADDR(s3)  # store ring 3 r0 in cmd list

    slli t1, a0, 1  # double radius for ring 2
    or t0, t1, t5
    sh t0, RING2_R0_ADDR(s3)

    add t2, t1, a0  # triple radius for ring 1
    or t0, t2, t5
    sh t0, RING1_R0_ADDR(s3)

    slli t1, a0, 2  # quadruple radius for ring 0
    or t0, t1, t5
    sh t0, RING0_R0_ADDR(s3)

    sw zero, ER_START_SB(s2)  # start Earthrise drawing

.L_scroll_loop:
    li a0, 1
    call frame_waitn  # wait one frame
    addi s6, s6, 1  # increment rate counter

    # update scroll coordinates
    lw t0, CANV0_SCROLL_COORD(s1)
    li t1, 0x0000FFFF
    and t2, t0, t1  # scroll x coord
    addi a0, t2, SCROLL_X  # updated scroll x coord
    mv a1, s7  # s7 is canvas x-dimension
    call floor_mod
    mv s5, a0  # save wrapped x coord (as there's a function call

    srli t0, t0, 16
    and t3, t0, t1  # scroll y coord
    addi a0, t3, SCROLL_Y  # updated scroll y coord
    mv a1, s8  # s8 is canvas y-dimension
    call floor_mod
    mv t3, a0  # wrapped y coord

    # update scroll offset to match new scroll y coord
    mul t4, t3, s7  # get scroll offset (s7 is canvas x-dimension)
    sw t4, CANV0_SCROLL_OFFSET(s1)

    # save updated scroll coordinates
    slli t3, t3, 16  # move y coord into upper 16 bits
    or t0, s5, t3   # combine updated coords back into word
    sw t0, CANV0_SCROLL_COORD(s1)

    li t0, CIRCLE_RATE
    bge s6, t0, .L_draw_loop
    j .L_scroll_loop

.section .data
.balign 2
    tm_cur:  # text mode cursor
        .byte 0, 0

.section .rodata
    message:
        .asciz "Press any key to begin animation.\n"
