# Isle.Computer - Asm String Library
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

.include "include/isle.inc"
.include "include/unicode.inc"

.section .text
.global int_strd
.global int_strx
.global strd_int
.global strx_int
.global utf8_decode
.global utf8_seq_len


# int_strd - integer to decimal string
#   a0: address to hold decoded string (up to 12 bytes including sign and null)
#   a1: integer
#   a2: unsigned flag (signed if a2==0, unsigned otherwise)
#   return: address of string start (usually higher address than a0)
#
int_strd:
    li   t5, 10          # base 10 (used for div)
    li   t6, 0           # negative flag
    addi a0, a0, 11      # start with least significant digit and work back
    sb   zero, 0(a0)     # store null terminator

    bnez a2, .L_div10_i  # skip invert if unsigned conversion
    bgez a1, .L_div10_i  # skip invert if integer is positive
    neg  a1, a1          # invert negative number
    li   t6, 1           # set negative flag

.L_div10_i:
    addi a0, a0, -1      # decrement string address
    mv   t4, a1          # copy number pre-division for remainder calc
    divu a1, a1, t5      # divide by 10
    mul  t0, a1, t5      # multiply quotient by 10
    sub  t0, t4, t0      # calculate remainder - faster than remu on FemtoRV
    addi t0, t0, 0x30    # add U+0030 offset to remainder
    sb   t0, 0(a0)       # write Unicode code point to string
    bnez a1, .L_div10_i  # if none of the number remains we're done with digits

    beqz t6, 0f          # skip minus sign unless we had negative signed number
    addi a0, a0, -1      # decrement string address
    li   t0, 0x2D        # minus sign (U+002D)
    sb   t0, 0(a0)       # write minus sign to string
0:
    ret


# int_strx - integer to hexadecimal string
#   a0: address to hold decoded string (8 bytes + null terminator)
#   a1: integer
#   return: address of string start
#
int_strx:
    li   t5, 0x3A      # threshold for converting to A-F
    addi t6, a0, 8     # start with least significant digit and work back
    sb   zero, 0(t6)   # store null terminator

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


# strd_int - decimal string to integer
#   a0: address of null-terminated string
#   return: integer
#
#   Supports negative numbers beginning with "-"
#   NB. values >2^32-1 overflow and wrap around
#
strd_int:
    li t1, 0   # clear return value
    li t2, 10  # decimal digit multiply and overflow

    lbu  t0, 0(a0)      # load first byte from decimal string
    li   t3, '-'        # hyphen-minus character
    xor  t4, t0, t3     # test first byte for minus sign (xor is zero if equal)
    seqz t3, t4         # t3=1 if minus set
    beqz t3, 1f         # if not negative, process byte as normal
    addi a0, a0, 1      # is negative, so increment string address for next byte
0:
    lbu  t0, 0(a0)      # load a byte from decimal string
1:
    addi t0, t0, -0x30  # subtract U+0030 (digit zero)
    bgeu t0, t2, 2f     # test for invalid char (inc. null): <0 or >9
    mul  t1, t1, t2     # shift existing number left (multiply by 10)
    add  t1, t1, t0     # add current digit
    addi a0, a0, 1      # increment string address
    j 0b
2:
    beqz t3, 3f  # minus flag set?
    neg  t1, t1  # negate if negative number
3:
    mv a0, t1  # set return value
    ret


# strx_int - hexadecimal string to integer
#   a0 : address of null-terminated string
#   return: integer
#
#   NB. values >2^32-1 return least significant 32 bits
#
strx_int:
    li t1, 0   # clear return value
    li t2, 16  # hex digit overflow
0:
    lbu  t0, 0(a0)      # load a byte from hex string
    beqz t0, 1f         # test for null (end of string)
    addi t0, t0, -0x61  # subtract U+0061 (lowercase A)
    bgez t0, .L_char_af # test for lowercase A-F
    addi t0, t0, 0x20   # add 0x20 to test for uppercase letters
    bgez t0, .L_char_af # test for uppercase A-F
    addi t0, t0, 7      # add 7 for 0-9 (a further 10 is added below)
    bgez t0, 1f         # reject in-between code points :;<=>? (U+003A-0x003F)
.L_char_af:
    addi t0, t0, 10     # add 10 for all chars
    bge  t0, t2, 1f     # test for invalid char >F
    bltz t0, 1f         # test for invalid char <0
    slli t1, t1, 4      # shift existing number left (multiply by 16)
    add  t1, t1, t0     # add current digit
    addi a0, a0, 1      # increment string address
    j 0b
1:
    mv a0, t1  # set return value
    ret


# utf8_decode - decode a single Unicode code point from a byte sequence
#   a0: string address
#   a1: address to hold decoded code point
#   return: next string address following non-zero code point
#           0 at string end (null code point)
#
utf8_decode:
    lbu t1, 0(a0)    # load 1st byte from string

1:  # 0xxxxxxx
    srli t0, t1, 7   # isolate MSB of 1st byte
    bnez t0, 2f      # branch if not one byte form
    mv   t6, t1      # save code point in t6

    addi a0, a0, 1   # advance string address one byte
    j    9f          # jump to end

2:  # 110xxxxx 10xxxxxx
    lbu  t2, 1(a0)   # load 2nd byte from string
    li   t5, 0b110   # two byte form: 110xxxxx
    srli t0, t1, 5   # isolate 3 MSB of first byte
    bne  t0, t5, 3f  # branch if not two byte form

    srli t0, t2, 6   # isolate 2 MSB of 2nd byte
    li   t5, 0b10    # continuation byte form: 10xxxxxx
    bne  t0, t5, 8f  # branch to error return if not continuation byte

    li   t5, 0x1F    # mask to select 5 LSB
    and  t5, t1, t5  # mask 1st byte
    slli t6, t5, 6   # shift bits from 1st byte into place

    li   t5, 0x3F    # mask to select 6 LSB
    and  t5, t2, t5  # mask 2nd byte
    or   t6, t6, t5  # combine bits from 2nd byte

    addi a0, a0, 2   # advance string address two bytes
    j    9f          # jump to end

3:  # 1110xxxx 10xxxxxx 10xxxxxx
    lbu  t3, 2(a0)   # load 3rd byte from string
    li   t5, 0b1110  # three byte form: 1110xxxx
    srli t0, t1, 4   # isolate 4 MSB of first byte
    bne  t0, t5, 4f  # branch if not three byte form

    srli t0, t2, 6   # isolate 2 MSB of 2nd byte
    li   t5, 0b10    # continuation byte form: 10xxxxxx
    bne  t0, t5, 8f  # branch to error return if not continuation byte
    srli t0, t3, 6   # isolate 2 MSB of 3rd byte
    bne  t0, t5, 8f  # branch to error return if not continuation byte

    li   t5, 0x0F    # mask to select 4 LSB
    and  t5, t1, t5  # mask 1st byte
    slli t6, t5, 12  # shift bits from 1st byte into place

    li   t5, 0x3F    # mask to select 6 LSB
    and  t5, t2, t5  # mask 2nd byte
    slli t5, t5, 6   # shift bits from 2nd byte
    or   t6, t6, t5  # combine bits from 2nd byte

    li   t5, 0x3F    # mask to select 6 LSB
    and  t5, t3, t5  # mask 3rd byte
    or   t6, t6, t5  # combine bits from 3rd byte

    addi a0, a0, 3   # advance string address three bytes
    j    9f          # jump to end

4:  # 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
    lbu  t4, 3(a0)   # load 4th byte from string
    li   t5, 0b11110  # four byte form: 11110xxx
    srli t0, t1, 3   # isolate 5 MSB of first byte
    bne  t0, t5, 8f  # branch if not four byte form

    srli t0, t2, 6   # isolate 2 MSB of 2nd byte
    li   t5, 0b10    # continuation byte form: 10xxxxxx
    bne  t0, t5, 8f  # branch to error return if not continuation byte
    srli t0, t3, 6   # isolate 2 MSB of 3rd byte
    bne  t0, t5, 8f  # branch to error return if not continuation byte
    srli t0, t4, 6   # isolate 2 MSB of 4th byte
    bne  t0, t5, 8f  # branch to error return if not continuation byte

    li   t5, 0x07    # mask to select 3 LSB
    and  t5, t1, t5  # mask 1st byte
    slli t6, t5, 18  # shift bits from 1st byte into place

    li   t5, 0x3F    # mask to select 6 LSB
    and  t5, t2, t5  # mask 2nd byte
    slli t5, t5, 12  # shift bits from 2nd byte
    or   t6, t6, t5  # combine bits from 2nd byte

    li   t5, 0x3F    # mask to select 6 LSB
    and  t5, t3, t5  # mask 3rd byte
    slli t5, t5, 6   # shift bits from 3rd byte
    or   t6, t6, t5  # combine bits from 3rd byte

    li   t5, 0x3F    # mask to select 6 LSB
    and  t5, t4, t5  # mask 4th byte
    or   t6, t6, t5  # combine bits from 4th byte

    addi a0, a0, 4   # advance string address four bytes
    j    9f          # jump to end

8:  # error
    li   t6, 0xFFFD  # error code point
    addi a0, a0, 1   # advance string address one byte

9:
    sw   t6, 0(a1)   # save code point
    bnez t6, 0f      # jump to end for non-zero UCP
    li   a0, 0       # return code is zero when UCP=0
0:
    ret


# utf8_seq_len - return length of UTF-8 sequence
#   a0: first byte of UTF-8 sequence
#   return: byte count (1-4) or 0 if invalid
#
utf8_seq_len:
    srli t0, a0, 8  # shift out the first byte
    bnez t0, .L_invalid_seq  # 0 unless a0 was larger than a byte
    la t6, utf8_seq_table
    srli t0, a0, 3  # select upper 5 bits
    add t6, t0, t6  # table entry address
    lbu a0, 0(t6)  # load table entry
    ret
.L_invalid_seq:
    li a0, 0
    ret


.section .rodata

.balign 4
utf8_seq_table:  # maps upper 5 bits of lead byte to sequence length
    .byte 1,1,1,1,1,1,1,1  # 00000-00111 0x00-0x3F (1 byte)
    .byte 1,1,1,1,1,1,1,1  # 01000-01111 0x40-0x7F (1 byte)
    .byte 0,0,0,0,0,0,0,0  # 10000-10111 0x80-0xBF (invalid)
    .byte 2,2,2,2          # 11000-11011 0xC0-0xDF (2 bytes)
    .byte 3,3              # 11100-11101 0xE0-0xEF (3 bytes)
    .byte 4                # 11110       0xF0-0xF7 (4 bytes)
    .byte 0                # 11111       0xF8-0xFF (invalid)
