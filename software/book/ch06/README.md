# Isle Chapter 6 Software

This RISC-V software accompanies [Input Output](http://projectf.io/isle/input-output.html), chapter 6 of _Building Isle_. See also: [Chapter 6 Hardware](../../../hardware/book/ch06/). Chapter 6 software uses instructions from the RV32IM ISA.

There's a blog post covering [Chapter 6 Software](https://projectf.io/isle/ch06-software.html).

## Chapter 6 Programs

* [echo.s](echo.s) - echos back a line of UTF-8 text (supports backspace)
* [framecount.s](framecount.s) - decimal frame counter
* [guess.s](guess.s) - number guessing game
* [resolution.s](resolution.s) - print display and text mode resolutions (demos reading hardware registers)

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

To change the software run for chapter 6, amend `FILE_SOFT` in your dev board's `top_ch06.v` file. For example, to run guess:

```verilog
localparam FILE_SOFT = {SW, "/book/ch06/guess.mem"};
```
