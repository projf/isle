# Isle Chapter 6 Software

This RISC-V software accompanies [Input Output](http://projectf.io/isle/input-output.html), chapter 6 of _Building Isle_. See also: [Chapter 6 Hardware](../../../hardware/book/ch06/). Chapter 6 software uses instructions from the RV32IM ISA.

There's a blog post covering [Chapter 6 Software](https://projectf.io/isle/ch06-software.html).

## Chapter 6 Programs

* [echo.s](echo.s) - echos back a line of UTF-8 text (supports backspace)
* [framecount.s](framecount.s) - decimal frame counter
* [guess.s](guess.s) - number guessing game
* [num_str.s](num_str.s) - tests number string conversion
* [resolution.s](resolution.s) - print display and text mode resolutions

## Building Isle Software

If you've previously built [chapter 5 software](../ch05/README.md), you have everything you need. Consult the [Isle Software Build](https://projectf.io/isle/software-build.html) guide for advice on setting up the toolchain.

Before building, Arch Linux and Fedora users need to edit `BIN_PREFIX` in `isle/software/book/ch06/Makefile`.

To build all the chapter 6 software:

```shell
cd isle/software/book/ch06
make
```

The software is assembled and turned into a .mem file suitable for loading into memory at design time.

To create a disassembled version of the linked software, run make with the program name and the `.dis` extension; for example:

```
cd isle/software/book/ch06
make echo.dis
```

To change the software run for chapter 6, amend `FILE_SOFT` in your dev board's `top_ch06.v` file. For example, to run echo:

```verilog
localparam FILE_SOFT = {SW, "/book/ch06/echo.mem"};
```

## Memory Map

Chapter 6 uses a simplified memory map with a 16-bit address that can address 64 KiB:

* `0x0000` - clut (to `0x00FF` - 256 bytes)
* `0x4000` - tram (to `0x5FFF` - 8K)
* `0x8000` - sysram (to `0xBFFF` - 16K)
* `0xC000` - system device (to `0xCFFF` - 4K)
* `0xD000` - graphics device (to `0xDFFF` - 4K)
* `0xE000` - uart device (to `0xEFFF` - 4K)

The stack pointer (**sp**) points to the address above the top of memory, `0xC000`, and we decrement it to allocate space on the stack.

You can find hardware registers in the device modules in [hardware/devs](../../../hardware/devs/).
