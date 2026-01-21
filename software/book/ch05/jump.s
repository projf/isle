# Isle.Computer - Jump! (Chapter 5)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. This software is designed for chapter 5 hardware only

.equ TRAM_BASE,      0x4000  # text mode ram (tram) base address
.equ HWREG_BASE,     0xC000  # hardware reg base address
.equ FRAME_FLAG,     0x0110  # signals start of new frame (offset to HWREG_BASE)
.equ FRAME_FLAG_CLR, 0x0114  # clear frame flag (offset to HWREG_BASE)

.equ TEXT_COLR, 0x0C000000  # 0xXY000000 Y=foreground colour and X=background
.equ ANIM_RATE, 60  # frames to wait between animation
.equ TEXT_LINE, 84  # number of characters in a line
.equ TRAM_DEPTH, 84*24  # number of characters in tram


.section .text
.global _start

_start:
    li sp, 0xC000  # stack grows down from here

.L_down:
    li s1, TRAM_BASE + (4*TEXT_LINE+4)*4

    li t0, TEXT_COLR | 0x006F  # U+006F - Latin Small letter O
    sw t0, 4(s1)
    addi s1, s1, 4*TEXT_LINE  # next line (4 bytes per char)
    li t0, TEXT_COLR | 0x003C  # U+003C - Less-than sign
    sw t0, 0(s1)
    li t0, TEXT_COLR | 0x004F  # U+004F - Latin Capital letter O
    sw t0, 4(s1)
    li t0, TEXT_COLR | 0x003E  # U+003E - Greater-than sign
    sw t0, 8(s1)
    addi s1, s1, 4*TEXT_LINE
    li t0, TEXT_COLR | 0x002F  # U+002F - Solidus or Slash
    sw t0, 0(s1)
    li t0, TEXT_COLR | 0x005C  # U+005C - Backslash
    sw t0, 8(s1)

    li a0, ANIM_RATE
    call frame_waitn
    call clr_text

.L_up:
    li s1, TRAM_BASE + (2*TEXT_LINE+4)*4

    li t0, TEXT_COLR | 0x005C  # U+005C - Backslash
    sw t0, 0(s1)
    li t0, TEXT_COLR | 0x006F  # U+006F - Latin Small letter O
    sw t0, 4(s1)
    li t0, TEXT_COLR | 0x002F  # U+002F - Solidus or Slash
    sw t0, 8(s1)

    addi s1, s1, 4*TEXT_LINE  # next line
    li t0, TEXT_COLR | 0x004F  # U+004F - Latin Capital letter O
    sw t0, 4(s1)
    addi s1, s1, 4*TEXT_LINE
    li t0, TEXT_COLR | 0x002F  # U+002F - Solidus or Slash
    sw t0, 0(s1)
    li t0, TEXT_COLR | 0x005C  # U+005C - Backslash
    sw t0, 8(s1)

    li a0, ANIM_RATE
    call frame_waitn
    call clr_text
    j .L_down


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


# clr_text - clear textmode (tram)
#   no arguments, no return
#
clr_text:
    li t1, TRAM_BASE
    li t2, TRAM_DEPTH
    li t3, 0x20  # clear with space and default colours
    li t6, 0

0:  # loop over tram clearing locations
    sw   t3, 0(t1)   # clear location
    addi t6, t6, 1   # increment counter
    addi t1, t1, 4   # increment address (word-based)
    blt  t6, t2, 0b
    ret
