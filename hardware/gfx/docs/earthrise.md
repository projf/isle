# Earthrise 2D Drawing Engine

The **Earthrise** module [[verilog src](../earthrise.v)] is a simple processor that decodes and executes graphics instructions for pixels, lines, triangles, rects, and circles. This doc provides a summary of the hardware module; see [Earthrise Programming](../../../docs/earthrise-programming.md) for guidance on drawing pixels, lines, and shapes.

Earthrise fetches an instruction from its command memory, decodes it, executes it, passing the drawing details to dedicated graphics hardware, before calculating the vram address to write pixels to. The CPU can write to the command memory and set Earthrise to drawing while it continues with other processing.

See the [2D Drawing](http://projectf.io/isle/2d-drawing.html) blog post for more information on the use of this module.

_I'll add more details on the internal operation of Earthrise in future updates._

## Parameters

* `CORDW` - signed coordinate width (bits)
* `WORD` - machine word size (bits)
* `CANV_SHIFTW` - vram address shift width (bits)
* `COLRW` - colour/pattern width (bits)
* `ER_ADDRW` - command list address width
* `VRAM_ADDRW` - vram address width (bits)

For Isle, `CORDW` must be set to **16** and `WORD` must be set to **32**.

## Signals

### Input

* `clk` - clock
* `rst` - reset
* `start` - start execution
* `canv_w`, `canv_h` - canvas width and height (in pixels)
* `canv_bpp` - canvas bits per pixel
* `cmd_list` - command list data
* `addr_base` - address of first pixel in canvas
* `addr_shift` - address shift bits

`addr_base` is the base address of the canvas buffer (first pixel) in vram.

The address shift, `addr_shift`, determines how the raw pixel address is split between vram address and pixel index.

Address shift is set based on the bits per pixel:

* 1 bit: `addr_shift = 5`
* 2 bit: `addr_shift = 4`
* 4 bit: `addr_shift = 3`
* 8 bit: `addr_shift = 2`

For example, 2 bits per pixel mean you have 16 pixels per 32-bit word, and 16 is 2^4.

### Output

* `pc` - Earthrise program counter (byte address)
* `vram_addr` - address in vram
* `vram_din` - vram data in
* `vram_wmask` - vram bit write mask
* `busy` - execution in progress
* `done` - commands complete (high for one tick)
* `instr_invalid` - invalid instruction

## Earthrise Command List

Earthrise instructions are all 16 bits long. Earthrise reads instructions from dedicated memory using its own program counter. This command list memory has a 32-bit data interface to match CPU data width, so each Earthrise address contains two 16-bit instructions. The command list memory uses byte addressing to ensure consistency with CPU addressing.

Isle uses 4 KiB of dual-port bram for the Earthrise command list. The CPU uses one port while Earthrise reads instructions from the second port. With 4 KiB of memory and 16-bit instruction, Earthrise can execute up to 2048 instructions in one run.
