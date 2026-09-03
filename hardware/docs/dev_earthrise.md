# Earthrise Device

The Earthrise device module [[dev_earthrise.v](../devs/dev_earthrise.v)] provides a CPU interface to the Earthrise drawing engine via its command list (erlist) and hardware registers.

See [earthrise](earthrise.md) and [Earthrise Programming](../../docs/earthrise-programming.md) for more details of the drawing engine itself. This Earthrise device and this documentation focus on the CPU control interface.

## Earthrise Command List

The CPU can access the Earthrise command list at offset `0x8000` from the start of the Earthrise device memory.

## Hardware Register Reference

Earthrise draws on a canvas.

### Read-Only

* `ER_BUSY_RO` - Earthrise is busy drawing (remains high if awaiting enable)
* `ER_CYCLE_COUNT_RO` - clock cycles the last drawing took to complete
* `ER_PC_RO` - Earthrise program counter
* `ER_INSTR_INVALID_RO` - invalid instruction flag has been raised

### Strobe

* `ER_START_SB` - start Earthrise
* `ER_RESET_SB` - reset (and stop) Earthrise

### Read-Write

Earthrise draws to a canvas defined by hardware registers. These canvas registers are separate from those used for [Display](dev_display.md).

* `ER_BPP` - bits per pixel; controls colour depth: 1, 2, 4, or 8 bit
* `ER_CANV_DIMS` - canvas dimension (bitmap pixels)
* `ER_VRAM_ADDR_BASE` - base vram word address of canvas
