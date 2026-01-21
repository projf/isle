# Isle Chapter 5 Software

Chapter 5 uses a simple RISC-V CPU, FemtoRV32 ([femtorv32_quark_bicycle](https://github.com/BrunoLevy/learn-fpga/tree/master/FemtoRV/RTL/PROCESSOR)), which supports the RV32I ISA. Later chapters will support other extensions, such as multiply (RV32M) and compressed instructions (RV32C). See also: [Chapter 5 Hardware](../../../hardware/book/ch05/).

These examples write to text mode memory, so it's a good idea to check out the [tram](../../../hardware/docs/tram.md) documentation. You can see the supported characters by looking at the font file [unifont-rom.mem](../../../res/fonts/unifont-rom.mem).

## Software Toolchain

Install a RISC-V toolchain:

* Debian/Ubuntu/Pop!_OS: `apt install gcc-riscv64-unknown-elf`
* Arch Linux: `pacman -S riscv64-elf-gcc`
* Fedora: `dnf install gcc-riscv64-linux-gnu`
* macOS: `brew install riscv-gnu-toolchain`

Windows users can run a RISC-V toolchain under Windows Subsystem for Linux (WSL).

## Building Isle Software

Before building, Arch Linux and Fedora users need to edit `BIN_PREFIX` in `isle/software/book/ch05/Makefile`.

To build all the chapter 5 software:

```shell
cd isle/software/book/ch05
make
```

The software is assembled and turned into a .mem file suitable for loading into memory at design time.

To create a disassembled version of the linked software, run make with the program name and the `.dis` extension; for example:

```
cd isle/software/book/ch05
make hello.dis
```

To change the software run for chapter 5, amend `FILE_SOFT` in your dev board's `top_ch05.v` file. For example, to run blink:

```verilog
localparam FILE_SOFT = {SW, "/book/ch05/blink.mem"};
```

## Chapter 5 Programs

* [hello.s](hello.s) - display "Hello!" using text mode
* [framecount.s](framecount.s) - hexadecimal frame counter
* [jump.s](jump.s) - jumping figure animation
* [palette.s](palette.s) - load a palette into clut and display each colour

## Memory Map

Chapter 5 uses a simplified memory map with a 16-bit address that can address 64 KiB:

* `0x0000` - clut (to `0x00FF` - 256 bytes)
* `0x4000` - tram (to `0x5FFF` - 8K)
* `0x8000` - sysram (to `0xBFFF` - 16K)
* `0xC000` - hardware registers

The stack pointer (**sp**) points to the address above the top of memory, `0xC000`, and we decrement it to allocate space on the stack.

There are two hardware registers:

* FRAME_FLAG (`0xC110`) - set to 1 at the start of each frame (read-only)
* FRAME_FLAG_CLR (`0xC114`) - writing to this register sets FRAME_FLAG to 0 (strobe)

The `frame_waitn` function in [framecount.s](framecount.s) demonstrates the use of these hardware registers.
