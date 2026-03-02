# Isle.Computer - Asm IO Library
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

.include "include/isle.inc"
.include "include/keyb.inc"

.section .text
.global read_ln
.global uart_rx_byte


# read_ln - read line of characters from input
#   a0: cursor address
#   a1: string address
#   a2: max string length including terminal null
#   a3: text colour
#   a4: visible cursor character (UCP)
#   a5: visible cursor colour
#   return: cursor address
#
#   NB. tm_* functions return current cursor address
#
read_ln:
    addi sp, sp, -48
    sw   ra, 44(sp)
    sw   s1, 40(sp)  # preserve starting cursor
    sw   s2, 36(sp)  # string address
    sw   s3, 32(sp)  # max string address including terminal null
    sw   s4, 28(sp)  # save cursor during utf8 decoding
    sw   s5, 24(sp)  # utf8 sequence length
    sw   s6, 20(sp)  # utf8 bytes processed
    sw   s7, 16(sp)  # addr of utf8_seq_buf
    sw   s8, 12(sp)  # text colour
    sw   s9,  8(sp)  # visible cursor character
    sw  s10,  4(sp)  # visible cursor colour
    #         0(sp)  # local var: ucp

    li t6, UART_DEV
    li t0, 1
    sw t0, UART_RX_EN(t6)  # enable UART RX

    lhu s1, 0(a0)  # load starting cursor
    mv s2, a1  # string address
    add s3, s2, a2  # max string address including terminal null
    addi s3, s3, -1  # leave space for null terminator
    mv s8, a3  # text colour
    mv s9, a4  # visible cursor character (UCP)
    mv s10, a5  # visible cursor colour
    la s7, utf8_seq_buf

    # initial visible cursor
    mv a1, s9
    mv a2, s10
    call tm_put

.L_read_ln_loop:
    mv s4, a0  # stash cursor before decoding UTF-8

.L_read_ln_rx:
    # receive and decode one code point
    call uart_rx_byte  # receive first byte of sequence
    sb a0, 0(s7)  # store first byte in utf8_seq_buf
    call utf8_seq_len  # get length of UTF-8 sequence in bytes
    beqz a0, .L_read_ln_rx  # skip if 0 (invalid / continuation byte)

    mv s5, a0  # sequence length
    li s6, 1   # bytes processed (we've already stored the first byte)

.L_read_ln_seq:
    beq s6, s5, .L_decode  # if we've read all bytes, decode
    call uart_rx_byte  # receive another byte
    add t6, s7, s6  # address to save this byte
    sb a0, 0(t6)
    addi s6, s6, 1
    j .L_read_ln_seq

.L_decode:
    add t6, s7, s5  # address to save this byte
    sb zero, 0(t6)  # store null terminator
    mv a0, s7
    add a1, sp, 0   # local var: ucp (use add in case offset changes)
    call utf8_decode

    mv a0, s4  # restore cursor after decoding UTF-8

    lw t6, 0(sp)  # load local var: ucp

    li t5, UNI_BACKSPACE
    beq t6, t5, .L_backspace  # branch if backspace

    li t5, UNI_CR
    beq t6, t5, .L_carriage_return  # branch to end if carriage return

.L_character:
    add t0, s2, s5
    bgt t0, s3, .L_read_ln_loop  # don't handle char if it won't fit in string

    mv t0, s7  # utf8_seq_buf pointer
.L_str_copy:
    lbu t5, 0(t0)
    beqz t5, .L_display_char  # if null we're done
    sb t5, 0(s2)  # store byte in string
    addi s2, s2, 1  # next buffer byte
    addi t0, t0, 1  # next sequence byte
    j .L_str_copy

.L_display_char:
    mv a1, t6  # UCP
    mv a2, s8  # text colour
    call tm_put_next  # display char in text mode and advance cursor
    mv a1, s9
    mv a2, s10
    call tm_put  # update visible cursor
    j .L_read_ln_loop

.L_backspace:
    lhu t0, 0(a0)  # load current cursor
    beq t0, s1, .L_read_ln_loop  # prevent backspace if cursor at start
    li a1, 0
    li a2, 0
    call tm_put  # remove old visible cursor
    call tm_backspace

    # delete character from string
    addi s2, s2, -1  # always back up one byte in string
    # back up over any continuation bytes (b10nnnnnn)
0:
    lbu t0, 0(s2)
    andi t0, t0, 0xC0  # isolate two most significant bits (0xC0 = b11000000)
    li t1, 0x80
    bne t0, t1, 1f  # we're done if it's not a continuation byte
    addi s2, s2, -1  # back another byte in string
    j 0b
1:
    mv a1, s9
    mv a2, s10
    call tm_put  # update visible cursor
    j .L_read_ln_loop

.L_carriage_return:
    li a1, 0
    li a2, 0
    call tm_put  # remove visible cursor

    li t6, UART_DEV
    sw zero, UART_RX_EN(t6)  # disable UART RX
    sb zero, 0(s2)  # store null terminator
    call tm_newline

    lw   s10, 4(sp)
    lw   s9,  8(sp)
    lw   s8, 12(sp)
    lw   s7, 16(sp)
    lw   s6, 20(sp)
    lw   s5, 24(sp)
    lw   s4, 28(sp)
    lw   s3, 32(sp)
    lw   s2, 36(sp)
    lw   s1, 40(sp)
    lw   ra, 44(sp)
    addi sp, sp, 48
    ret


# uart_rx_byte - load one byte from uart receiver
#   no arguments
#   return: data byte from uart
#
uart_rx_byte:
    li   t6, UART_DEV
.L_uart_rx_loop:
    lw   t0, UART_RX_LEN(t6)  # is there data waiting
    beqz t0, .L_uart_rx_loop  # loop if UART data isn't ready
    lw   a0, UART_RX_DAT(t6)  # load byte from UART (hwreg is word)
    ret


.section .data

.balign 4
utf8_seq_buf:
    .zero 5  # up to four bytes + null terminator
