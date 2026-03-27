# Isle.Computer - Asm Text Mode Library
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. all functions use and return the cursor address in a0

.include "include/isle.inc"
.include "include/unicode.inc"

.section .text
.global tm_backspace
.global tm_clr
.global tm_clr_line
.global tm_cur_decx
.global tm_cur_decy
.global tm_cur_incx
.global tm_cur_incy
.global tm_delete
.global tm_newline
.global tm_print
.global tm_put
.global tm_put_next


# tm_backspace - decrement cursor x-coord then delete char
#   a0: cursor address
#   return: cursor address
#
tm_backspace:
    addi sp, sp, -16
    sw   ra, 12(sp)

    call tm_cur_decx  # decrement cursor x-coord (handles wrapping)
    call tm_delete  # delete character at current position

    lw   ra, 12(sp)
    addi sp, sp, 16
    ret


# tm_clr - clear text mode (tram) and reset cursor
#   a0: cursor address
#   return: cursor address
#
tm_clr:
    sh zero, 0(a0)  # set cursor to (0,0)

    li t6, GFX_DEV
    lw t5, TRAM_DEPTH(t6)  # depth of tram in chars (words)
    slli t5, t5, 2  # convert depth in chars to bytes
    li t6, TRAM_BASE
    add t5, t6, t5  # end address (one after last address to clear)

0:  # loop over tram clearing locations (do-while loop assumes TRAM_DEPTH ≥ 1)
    sw zero, 0(t6)   # clear location
    addi t6, t6, 4   # next word
    blt t6, t5, 0b   # stop when we reach end address
    ret


# tm_clr_line - clear to end of line, returns cursor unchanged
#   a0: cursor address
#   return: cursor address
#
tm_clr_line:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   s1,  8(sp)
    lhu  t0,  0(a0)  # load cursor
    sw   t0,  4(sp)  # save existing cursor so we can restore it after clear

    li t6, GFX_DEV
    lhu s1, TEXT_DIMS(t6)  # load width from lower half of TEXT_DIMS

0:
    call tm_delete
    lbu t0, 0(a0)  # load x-coord
    addi t0, t0, 1  # increment x-cursor
    beq t0, s1, 1f  # stop if we're at end of line
    sb t0, 0(a0)  # store cursor x-coord
    j 0b

1:
    lhu  t0,  4(sp)  # load original cursor from stack
    sh   t0,  0(a0)  # store original cursor value

    lw   s1,  8(sp)  # restore original cursor
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret


# tm_cur_decx - decrement cursor x-coord, wrap if required
#   a0: cursor address
#   return: cursor address
#
tm_cur_decx:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   s1,  8(sp)

    li t6, GFX_DEV
    lhu t1, TEXT_DIMS(t6)  # load width from lower half of TEXT_DIMS

    lbu s1, 0(a0)    # load x-coord
    addi s1, s1, -1  # decrement
    bgez s1, 0f      # skip adjustment if within range

    add s1, s1, t1    # add width to keep in range
    call tm_cur_decy  # move up a line if we wrapped
0:
    sb s1, 0(a0)  # store x-coord

    lw   s1,  8(sp)
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret


# tm_cur_decy - decrement cursor y-coord, wrap if required
#   a0: cursor address
#   return: cursor address
#
tm_cur_decy:
    li t6, GFX_DEV
    lhu t2, TEXT_DIMS+2(t6)  # load height from upper half of TEXT_DIMS

    lbu t5, 1(a0)    # load y-coord
    addi t5, t5, -1  # decrement
    bgez t5, 0f      # skip adjustment if within range
    add t5, t5, t2   # add height to keep in range
0:
    sb t5, 1(a0)  # store y-coord
    ret


# tm_cur_incx - increment cursor x-coord, wrap if required
#   a0: cursor address
#   return: cursor address
#
tm_cur_incx:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   s1,  8(sp)

    li t6, GFX_DEV
    lhu t1, TEXT_DIMS(t6)  # load width from lower half of TEXT_DIMS

    lbu s1, 0(a0)   # load x-coord
    addi s1, s1, 1  # increment
    blt s1, t1, 0f  # skip adjustment if within range

    sub s1, s1, t1    # subtract width to keep in range
    call tm_cur_incy  # move down a line if we wrapped
0:
    sb s1, 0(a0)  # store x-coord

    lw   s1,  8(sp)
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret


# tm_cur_incy - increment cursor y-coord, wrap if required
#   a0: cursor address
#   return: cursor address
#
tm_cur_incy:
    li t6, GFX_DEV
    lhu t2, TEXT_DIMS+2(t6)  # load height from upper half of TEXT_DIMS

    lbu t5, 1(a0)   # load y-coord
    addi t5, t5, 1  # increment
    blt t5, t2, 0f  # skip adjustment if within range
    sub t5, t5, t2  # subtract height to keep in range
0:
    sb t5, 1(a0)  # store y-coord
    ret


# tm_delete - delete char at current cursor without moving cursor
#   a0: cursor address
#   return: cursor address
#   see also: tm_backspace
#
tm_delete:
    li a1, 0  # unicode code point
    li a2, 0  # text colour
    j tm_put  # tail call


# tm_newline - move cursor to start of next line
#   a0: cursor address
#   return: cursor address
#
tm_newline:
    addi sp, sp, -16
    sw   ra, 12(sp)

    call tm_cur_incy  # move down a line
    sb zero, 0(a0)  # zero cursor x-coord

    lw   ra, 12(sp)
    addi sp, sp, 16
    ret


# tm_print - print string in text mode at cursor position and move cursor
#   a0: cursor address
#   a1: string address
#   a2: text colour
#   return: cursor address
#
tm_print:
    addi sp, sp, -32
    sw   ra, 28(sp)
    sw   s1, 24(sp)  # cursor address
    sw   s2, 20(sp)  # string address
    sw   s3, 16(sp)  # text colour
    # local:ucp, 0(sp)

    mv s1, a0  # save cursor address
    mv s2, a1  # save string address
    mv s3, a2  # save text colour

.L_print_loop:
    # turn string into series of Unicode code points
    # a0: string address
    # a1: address to hold decoded code point
    mv a0, s2
    mv a1, sp  # local:ucp, 0(sp)
    call utf8_decode
    beqz a0, 2f  # return if at string end (null)
    mv s2, a0  # save updated string address

    mv a0, s1  # restore cursor address
    lw a1, 0(sp)  # local:ucp, 0(sp)
    li t5, UCS_LINE_FEED
    beq a1, t5, 1f  # branch line feed

    mv a2, s3  # restore text colour
    call tm_put_next
    j .L_print_loop

1:
    call tm_newline
    j .L_print_loop

2:
    mv   a0, s1  # return updated cursor address

    lw   s3, 16(sp)
    lw   s2, 20(sp)
    lw   s1, 24(sp)
    lw   ra, 28(sp)
    addi sp, sp, 32
    ret


# tm_put - put char in textmode at current cursor position
#   a0: cursor address
#   a1: unicode code point
#   a2: text colour
#   return: cursor address
#
#   NB. does not move cursor; does nothing if cursor outside tram address space
#
tm_put:
    lbu t4, 0(a0)  # x-coord
    lbu t5, 1(a0)  # y-coord

    li t6, GFX_DEV
    lhu t1, TEXT_DIMS(t6)  # load width from lower half of TEXT_DIMS
    lw t3, TRAM_DEPTH(t6)  # depth of tram in chars (words)

    mul t0, t5, t1  # tram offset: y
    add t0, t0, t4  # tram offset: y+x
    bge t0, t3, 0f  # don't put char if cursor outside tram
    slli t0, t0, 2  # multiply offset by 4 for byte addressing

    li t6, TRAM_BASE  # tram base address
    add t6, t6, t0    # add offset to base address

    # tram memory locations: bits 0-20 UCP; bits 24-31 colour
    slli t0, a2, 24  # shift colour into upper 8 bits
    or t0, t0, a1  # combine colour and UCP
    sw  t0, 0(t6)  # update character
0:
    ret  # return a0 unchanged


# tm_put_next - put char in textmode at current cursor position and inc cursor
#   a0: cursor address
#   a1: unicode code point
#   a2: text colour
#   return: cursor address
#
tm_put_next:
    addi sp, sp, -16
    sw   ra, 12(sp)

    call tm_put  # returns current cursor address
    call tm_cur_incx  # increment cursor x-coord

    lw   ra, 12(sp)
    addi sp, sp, 16
    ret
