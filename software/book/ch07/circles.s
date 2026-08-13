# Isle.Computer - Circles (Chapter 7)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

.include "include/isle.inc"
.include "include/dev_display.inc"
.include "include/dev_earthrise.inc"
.include "include/dev_uart.inc"

# text colour (index to clut)
.equ TEXT_COLR, 0x05  # 0xXY Y=foreground colour and X=background


# Earthrise command list addresses - must match drawings/circle-rings.mem
.equ XT_ADDR,  0x02
.equ YT_ADDR,  0x04
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
    add s3, s3, s2  # add earthrise device address to offset

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


.er_loop:

    # choose random x-coordinate (0-335)
    li a0, 0
    li a1, 335
    call rand_pseudo
    li t5, ER_XT   # x-translation opcode
    or t0, a0, t5  # combine random coordinate with opcode
    sh t0, XT_ADDR(s3)  # store xt in cmd list

    # choose random y-coordinate (0-191)
    li a0, 0
    li a1, 191
    call rand_pseudo
    li t5, ER_YT   # y-translation opcode
    or t0, a0, t5  # combine random coordinate with opcode
    sh t0, YT_ADDR(s3)  # store yt in cmd list

    # choose random radius step (2-12)
    li a0, 2
    li a1, 12
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

    sw zero, ER_START_SB(s2)  # start Earthrise

    li a0, 10
    call frame_waitn

    j .er_loop


.exit:
    j .exit


.section .data
.balign 2
    tm_cur:  # text mode cursor
        .byte 0, 0

.section .rodata
    message:
        .asciz "Press any key to begin animation.\n"
