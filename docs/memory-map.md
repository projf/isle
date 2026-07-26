# Memory Map

Isle has a 24-bit memory map. Keeping addresses short and memorable is helpful when working at a low level and with assembler. This memory map will almost certainly change as Isle evolves.

The upper 8M of memory is for system ram, including the stack. The lower 8M is used by other memories and devices. For ease of reading, we write 24-bit Isle addresses as `0xnn_nnnn`, e.g. `0x40_4024` (an address in vram).

* 0x0 - boot rom (2K), vector table, interrupt service routines (TBC)
* 0x1 - system rom (1M) - OS and system libraries (TBC)
* 0x2 - *reserved*
* 0x3 - *reserved*
* 0x4 - vram - video ram (64K)
* 0x5 - graphics memories
    - 0x50 - tram (8K)
    - 0x58 - clut (1K = 256 x word addresses, 15-bits used)
* 0x6 - devices - 16 x 64 KiB device slots (slots are temporarily fixed until chapter 9)
    - 0x60 - system
    - 0x61 - display
    - 0x62 - uart
* 0x7 - sound memory (TBC)
* 0x8 - system memory (16K, but can expand up to 8M, minus stack)
* 0xF - stack (4K) down from `0xFF_FFF0`

## Stack Memory

We have a separate stack memory so it can reside in bram, even when sysram is in higher latency sdram.

The stack grows down from `0xFF_FFF0` to avoid the start addressing being outside the 24-bit address range (`0x100_0000`). We lose 16 bytes, but everything is otherwise the same.

If using full 8M of address space for sysram, remember to exclude stack in address decoding.

## Unmapped Address

The CPU hangs if it tries to read or write to an address that's not in a decoded range; whether reading/writing data or fetching instructions. This is preferable to the read returning 0 or the write being silently discarded. We don't have interrupt support yet, but when we do this will trigger a fault you'll be able to see. When running software under the Verilator/SDL simulation, you will see bus faults thanks to a $display message.

If the CPU accesses an address within a valid device range, then it's up to the device to report whether the address is valid or not. This functionality isn't implemented yet.
