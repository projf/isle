# Display Device

The display device module [[dev_display.v](../gfx/dev_display.v)] composites graphics output from text and bitmap graphics (canvases). The CPU controls the display device through hardware registers.

Conceptually, this module is simple, but it's one of the more complex in Isle because it handles precise timing and clock domain crossing (CDC).

To avoid confusion between Verilog registers (reg), and Isle hardware registers, I'll refer to the Isle hardware registers as **hwreg** in this doc.

_more details on parameters and I/O signals to follow_

## Hardware Register CDC

The CPU reads and writes hwreg in the sys clock domain. The display hardware needs to read them in the pix clock domain. Other Isle components solve this problem with dual-port bram; however, the display hardware needs to access many of the hwreg simultaneously. To make this work, the hwreg are implemented as **two arrays** of Verilog registers (flip flops), one in the sys clock domain, and one in the pix clock domain. Once per frame, we stop accepting writes from the CPU, let the sys hwreg settle, then copy all values from the sys to the pix registers. The CPU is blocked from making further writes by the busy-write signal (`wbusy`). A write is safely captured and made when the hwreg are no longer busy.

Once per frame, when diaplay coordinate dy = -3 (three lines before the active display begins), the hardware registers are copied from the sys to pix clock domains. This means that changes only take affect after this point. If you want to scroll this frame, you need to update the scroll registers before dy hits -3.

`CANV0_SCROLL_COORD` and `CANV0_SCROLL_OFFSET` must be set consistently. It's unlikely, but possible you could update one then have the second update blocked by the hwreg update, so the scrolling glitches. The way to avoid this risk is to update scroll registers long before dy = -3.

## Hardware Register Reference

For hardware, these are defined in [dev_display.v](../gfx/dev_display.v), while for software they're in [dev_display.inc](../../software/include/dev_display.inc).

NB. Hardware registers must be written as **whole words** from the CPU side. Not as bytes or half words. Use the `sw` RISC-V instruction.

### Read-Only

* `DISP_DIMS_RO` - display dimensions (pixels)
* `BMAP_DIMS_RO` - bitmap graphics dimensions (pixels)
* `TEXT_DIMS_RO` - text dimensions (half-width characters)
* `FRAME_FLAG_RO` - set once per frame (clear with FRAME_FLAG_SB)
* `TRAM_DEPTH_RO` - depth of tram (half-width characters)

### Strobe

* `FRAME_FLAG_SB` - clears frame flag (FRAME_FLAG_RO)

### Read-Write

#### Display

* `DISP_VISIBLE` - text mode and canvas visibility inc. transparency
    - 1st byte is visibility (bit0=textmode, bit1=canvas0)
    - 2nd byte transparency (bit8=textmode, bit9=canvas0)
* `DISP_BG_COLR` - display background colour RGB555

#### Text Mode

* `TEXT_WIN_START` - display coordinates for start of text display window (y,x)
* `TEXT_WIN_END` - display coordinates for end of text display window (y,x)
* `TEXT_SCALE` - text scale relative to display dimensions
* `TEXT_PAL` - text palette offset in clut
* `TEXT_TIDX` - transparent text colour index (DISP_VISIBLE controls if transparency is enabled)
* `TEXT_SCROLL_OFFSET` - text scrolling offset (half-width characters)

#### Canvas

* `CANV0_WIN_START` - display coordinates for start of canvas display window (y,x)
* `CANV0_WIN_END` - display coordinates for end of canvas display window (y,x)
* `CANV0_SCALE` - canvas scale relative to display dimensions
* `CANV0_PAL` - canvas palette offset in clut
* `CANV0_TIDX` - transparent canvas colour index (DISP_VISIBLE controls if transparency is enabled)
* `CANV0_DIMS` - canvas dimension (bitmap pixels)
* `CANV0_VRAM_ADDR_BASE` - base vram word address of canvas
* `CANV0_BPP` - canvas bits per pixel; controls colour depth: 1, 2, 4, or 8 bit
    - `canv0_addr_shift` signal is derived from this
* `CANV0_SCROLL_COORD` - canvas scroll coordinate (must match CANV0_SCROLL_OFFSET)
* `CANV0_SCROLL_OFFSET` - pixel offset of canvas scroll line

When scrolling, the `CANVn_SCROLL_OFFSET` must be set to the y-value of `CANVn_SCROLL_COORD` multiplied by the canvas width from `CANVn_DIMS`. This avoids the need for a hardware multiplier in the canvas display address generator (canv_disp_agu).

_This is currently a single canvas, but a second canvas will be added in future with prefix CANV1\_._
