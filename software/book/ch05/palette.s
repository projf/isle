# Isle.Computer - Palette (Chapter 5)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. This software is designed for chapter 5 hardware only

.equ CLUT_BASE, 0x0000  # colour lookup table base address
.equ TRAM_BASE, 0x4000  # text mode ram (tram) base address

.equ PAL_NAME, pal_go  # name of palette in data section
.equ PAL_SIZE, 16  # number of colours in palette (must match PAL_NAME)

.equ CHAR, 0x2588  # U+2588 - Full block
# .equ CHAR, 0x3F  # U+003F - Question mark


.section .text
.global _start

_start:
    li sp, 0xC000  # stack grows down from here
    li s1, TRAM_BASE
    li s2, CLUT_BASE
    li s11, CHAR

    # load palette config
    li t4, PAL_SIZE  # load palette size
    la t6, PAL_NAME  # load address of palette in data section

    # load palette into colour lookup table
.L_load_pal:
    lhu t3, 0(t6)  # load palette entry (unsigned half word)
    sw t3, 0(s2)  # save palette to CLUT
    addi s2, s2, 4  # next CLUT address
    addi t6, t6, 2  # next data half word
    addi t4, t4, -1  # count down
    bnez t4, .L_load_pal

    # write characters in all palette colours
    li t4, PAL_SIZE  # number of colours in palette
    li t5, 0  # palette index
.L_disp_pal:
    slli t0, t5, 24  # shift colour index into position
    or t0, s11, t0  # combine char code point with colour
    sw t0, 0(s1)  # store to tram
    addi t5, t5, 1  # next palette entry
    addi s1, s1, 4  # next tram address (+1 word)
    blt t5, t4, .L_disp_pal

.exit:
    j .exit


.section .data
.balign 2

pal_mono:  # palette: Mono-2
    .hword 0x10A5  # 0x0 - (04, 05, 05)
    .hword 0x7BFE  # 0x1 - (30, 31, 30)

pal_aqua:  # palette: Aqua-4
    .hword 0x00AB  # 0x0 - (00, 05, 11)
    .hword 0x0171  # 0x1 - (00, 11, 17)
    .hword 0x02F7  # 0x2 - (00, 23, 23)
    .hword 0x4FDC  # 0x3 - (19, 30, 28)

pal_go:  # palette Go-16
    .hword 0x0C43  # 0x0 - (03, 02, 03)
    .hword 0x0CAD  # 0x1 - (03, 05, 13)
    .hword 0x096F  # 0x2 - (02, 11, 15)
    .hword 0x0A76  # 0x3 - (02, 19, 22)
    .hword 0x058A  # 0x4 - (01, 12, 10)
    .hword 0x02CD  # 0x5 - (00, 22, 13)
    .hword 0x34F2  # 0x6 - (13, 07, 18)
    .hword 0x5DB5  # 0x7 - (23, 13, 21)
    .hword 0x44C5  # 0x8 - (17, 06, 05)
    .hword 0x458E  # 0x9 - (17, 12, 14)
    .hword 0x7189  # 0xA - (28, 12, 09)
    .hword 0x7ACF  # 0xB - (30, 22, 15)
    .hword 0x65C2  # 0xC - (25, 14, 02)
    .hword 0x7EC0  # 0xD - (31, 22, 00)
    .hword 0x5AF1  # 0xE - (22, 23, 17)
    .hword 0x7399  # 0xF - (28, 28, 25)
