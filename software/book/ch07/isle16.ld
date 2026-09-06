/* Isle.Computer - Chapter 7 16K Linker Script */
/* Copyright Will Green and Isle Contributors */
/* SPDX-License-Identifier: MIT */

ENTRY(_start)

MEMORY
{
    BRAM       (RWX) : ORIGIN = 0x800000, LENGTH = 0x4000
    STACK_BRAM (RW)  : ORIGIN = 0xFFF000, LENGTH = 0x1000
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

    .rodata :
    {
        . = ALIGN(4);
        *(.rodata)
    } >BRAM

    .stack (NOLOAD) :
    {
        . = ALIGN(16);
        _stack_bottom = .;
        . = ORIGIN(STACK_BRAM) + LENGTH(STACK_BRAM) - 16;
        . = ALIGN(16);
        _stack_top = .;
    } >STACK_BRAM
}
