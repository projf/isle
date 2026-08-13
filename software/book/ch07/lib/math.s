# Isle.Computer - Asm Maths Library (Chapter 7)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

.include "include/isle.inc"

.section .text
.global floor_mod


# floor_mod - reduce value to range [0, n)
#   a0: signed value
#   a1: n (modulus; must be > 0)
#   return: a0 modulo n
#
floor_mod:
    rem a0, a0, a1  # truncated remainder; retains sign of a0
    bgez a0, 1f     # skip if already positive
    add a0, a0, a1  # shift into positive range
1:
    ret
