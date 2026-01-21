# Isle.Computer - Hello! (Chapter 5)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# NB. This software is designed for chapter 5 hardware only

.equ TRAM_BASE, 0x4000  # text mode ram (tram) base address


.section .text
.global _start

_start:
    li sp, 0xC000  # stack grows down from here
    li s1, TRAM_BASE

    li t0, 0x0C000048  # colour 0xC - U+0048 - Latin Capital letter H
    sw t0, 0(s1)
    li t0, 0x0C000065  # colour 0xC - U+0065 - Latin Small letter E
    sw t0, 4(s1)
    li t0, 0x0C00006C  # colour 0xC - U+006C - Latin Small letter L
    sw t0, 8(s1)
    li t0, 0x0C00006C  # colour 0xC - U+006C - Latin Small letter L
    sw t0, 12(s1)
    li t0, 0x0C00006F  # colour 0xC - U+006F - Latin Small letter O
    sw t0, 16(s1)
    li t0, 0x03000021  # colour 0x3 - U+0021 - Exclamation mark
    sw t0, 20(s1)

.exit:
    j .exit
