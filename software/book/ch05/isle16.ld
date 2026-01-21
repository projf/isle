/* Isle.Computer - Chapter 5 16K Linker Script */
/* Copyright Will Green and Isle Contributors */
/* SPDX-License-Identifier: MIT */

ENTRY(_start)

MEMORY
{
    BRAM (RWX) : ORIGIN = 0x8000, LENGTH = 0x4000
}

SECTIONS
{
    .text :
    {
        . = ALIGN(4);
        *(.text)
    } >BRAM

    .data :
    {
        . = ALIGN(4);
        *(.data)
    } >BRAM
}
