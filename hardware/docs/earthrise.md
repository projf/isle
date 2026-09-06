# Earthrise 2D Drawing Engine

The Earthrise module [[earthrise.v](../gfx/earthrise.v)] is a simple processor that decodes and executes graphics instructions for pixels, lines, triangles, rects, and circles. This doc provides a summary of the hardware module; see [Earthrise Programming](../../docs/earthrise-programming.md) for guidance on drawing pixels, lines, and shapes.

Earthrise fetches an instruction from its command memory, decodes it, executes it, passing the drawing details to dedicated graphics hardware, before calculating the memory address with the [canvas draw AGU](canv_draw_agu.md), and writing to [vram](vram.md). The CPU can write drawing instructions to the Earthrise command list and set Earthrise to drawing while it continues with other processing.

See the [2D Drawing](http://projectf.io/isle/2d-drawing.html) blog post for more information on the use of this module.

_I'll add more details on the internal operation of Earthrise in future updates._

## Parameters

* `CORDW` - signed coordinate width (bits)
* `WORD` - machine word size (bits)
* `CANV_SHIFTW` - vram address shift width (bits)
* `COLRW` - colour/pattern width (bits)
* `ER_ADDRW` - command list address width
* `VRAM_ADDRW` - vram address width (bits)

At present, Isle has `CORDW=16` but Earthrise uses 12-bit coordinates internally. This is transparent to you as a user of Earthrise, but it does limit the drawable area to around 2000x2000 pixels.

## Signals

### Input

* `clk` - clock
* `rst` - reset
* `en` - enable
* `start` - start execution
* `canv_dims` - canvas dimensions (width in lower CORDW bits, height in upper CORDW bits)
* `canv_bpp` - canvas bits per pixel (colour depth)
* `cmd_list` - command list data (2 x 16-bit instructions)
* `vram_addr_base` - base word address of canvas in vram

The `en` signal is useful for bus arbitration and for slowing down drawing to make the process visible. You can reset with `rst` at any time, even when Earthrise is not enabled. Resetting aborts currently drawing and resets all colours to index 1; see also [clut](clut.md).

`vram_addr_base` is the base _word_ address of the canvas buffer in vram.

Earthrise is little endian to match the RISC-V CPU, so the instruction in the lower 16 bits of `cmd_list` is executed first.

`canv_dims`, `canv_bpp`, and `vram_addr_base` are latched at the start of executing an Earthrise command list; changing these values while drawing is in progress has no effect.

`canv_bpp` supports the following values:

* 1 bit (2 colours)
* 2 bit (4 colours)
* 4 bit (16 colours)
* 8 bit (256 colours)

### Output

* `pc` - Earthrise program counter (byte address)
* `vram_addr` - vram word address
* `vram_din` - vram data in
* `vram_wmask` - vram bit-write mask
* `busy` - execution in progress or writing to vram
* `cycle_cnt` - number of clock cycles to execute command list
* `instr_invalid` - invalid instruction

See [vram](vram.md) for details on vram write mask.

The Earthrise program counter, `pc` is read only. See [Earthrise Programming](../../docs/earthrise-programming.md) for controlling Earthrise execution flow with Earthrise instructions.

You can use `cycle_cnt` to learn how many clock cycles Earthrise took to execute your command list. This isn't adjusted for enable (`en`) so cycle counts will vary if Earthrise is sharing vram with other devices.

When Earthrise has finished executing its command list and writes have gone to memory, `busy` goes low. Once `busy` has gone low Earthrise is ready to run more commands. The vram interface handles arbitration between writers.

If Earthrise encounters an invalid instruction, `busy` goes low and `instr_invalid` goes high until Earthrise receives a new start signal. You can see Earthrise debug output by defining `DEBUG` in simulation; this is already on by default for Verilator; see [verilator.mk](../../boards/verilator/verilator.mk).

## Earthrise Command List

Earthrise instructions are all 16 bits long. Earthrise reads instructions from dedicated memory using its own program counter for addressing. This command list memory has a 32-bit data interface to match the RISC-V CPU, so each Earthrise address contains two 16-bit instructions. The command list memory uses byte addressing for consistency with CPU addressing. Earthrise execution always starts from address 0.

Isle uses 4 KiB of dual-port bram for the Earthrise command list. The CPU uses one port to read/write drawing instructions, while Earthrise reads instructions from the second port. With 4 KiB of memory and 16-bit instructions, Earthrise can hold up to 2048 instructions.

The command list depth must be a power of two; Earthrise relies on this to detect the end of the command list when its PC overflows. See the logic in the Earthrise `DECODE` state.

See [erlist](erlist.md) for details on the command list module.
