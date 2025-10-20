# Earthrise Programming

This doc provides an overview and reference for Earthrise graphics programming. Take a look at [Isle Graphics](https://projectf.io/isle/graphics.html) for blog posts on this topic. You'll find reference documentation for the Earthrise hardware (Verilog module) in [graphics hardware](../hardware/gfx).

## Overview

Earthrise instructions are 16 bits long and have one of two formats:

* 4-bit opcode and 12-bit value
* 4-bit opcode, a 4-bit function, and 8-bit options or value

The following opcodes are currently supported:

* `0x0 - 0x9` - load immediate into coordinate register
* `0xC` - load immediate into colour register and control instructions
* `0xD` - drawing

A coordinate example **0x2040**:

* The 4-bit opcode is **0x2** - load immediate into coordinate register `x1`
* The 12-bit value is **0x040** - value is 0x40 or 64 in decimal

Breaking down a drawing example **0xD301**:

* The 4-bit opcode is **0xD** - draw command
* The 4-bit function is **0x3** - triangle
* The 8-bit binary options are **00000001** - a filled triangle in colour A

_The coordinates and colour for the triangle come from the registers._

You can generate Earthrise instructions either through the Isle system library (to follow with the CPU) or by using the provided assembler [erasm](../tools/erasm/), which converts mnemonics to hexadecimal instructions.

For example, using mnemonics, we can draw a line between (8, 16) and (16, 24) in line colour A (which we set to 10):

```
lca 10  # set line colour A to 10
x0   8  # set coordinate x0 to 8
y0  16
x1  16
y1  24
draw line ca  # draw line between (x0, y0) and (x1, y1) in line colour A
```

## Coordinates

Earthrise uses **coordinate registers** to define shapes.

Coordinate registers are signed 12-bit values, allowing a range from -2048 to +2047. There are four coordinate register pairs, `(x0, y0)` to `(x3, y3)`, and one translation register pair `(xt, yt)`.

Coordinate registers are signed and 12-bits long, covering -2048 to +2047. There are four pairs of coordinate registers `(x0, y0)` to `(x3, y3)` for defining shapes and one pair of translation registers. For example, when you tell Earthrise to draw a line, it starts at `(x0, y0)` and ends at `(x1, y1)`.

The load immediate opcode for each register:

* **0x0**, **0x1** - `(x0, y0)`
* **0x2**, **0x3** - `(x1, y1)`
* **0x4**, **0x5** - `(x2, y2)`
* **0x6**, **0x7** - `(x3, y3)`
* **0x8**, **0x9** - `(xt, yt)` - translation registers

The **translation** registers `(xt, yt)` are added to the initial coordinates used by drawing functions. For example, when `(xt=4, yt=8)`, all coordinates will be shifted right 4 pixels and down 8 pixels. You can use negative translation values, so `(xt=-4, yt=0)` will move the x coordinates left by 4 pixels. Translation applies to all subsequent coordinates, so you can define a complex shape, then update the translation registers to move the whole shape without having to revise hundreds of coordinates.

Taking the line example from the overview (above):

```
0xC00A  # lca 10
0x0008  # x0   8
0x1010  # y0  16
0x2010  # x1  16
0x3018  # y1  24
0xD100  # draw line ca
```

To express negative values in hex, use two's complement: -1 is 0xFFF and -16 is 0xFF0. For example, instruction `0x8FFC` sets `xt` to -4, which shifts coordinates left 4 pixels.

Earthrises uses coordinates to determine which address in [VRAM](../hardware/mem/docs/vram.md) to write to.

A few things of note:

* There is no way to read a value from an Earthrise register.
* When drawing circles (discussed below), the radius `r0` uses the same register and opcode as `x1`.
* All zeros is a valid instruction: load 0 into register `x0`.

Future Features:

* 16-bit coordinate registers with 4 bits for sub-pixel (fractional) positioning (Q12.4)
* Use of coordinate registers as blitter addresses

## Colour Registers

Earthrise uses **colour registers** to define the colours shapes are drawn in.

Colour registers are 8 bits in length, supporting 2-256 colours. There are two colour registers for lines and two for fills; drawing instructions (discussed below) select colour A or B. A colour load immediate instruction consists of **0xC** (for colour) followed by a 4-bit register ID and an 8-bit immediate.

The load immediate opcode for each register:

* **0xC0** - line colour A (lca)
* **0xC1** - line colour B (lcb)
* **0xC2** - fill colour A (fca)
* **0xC3** - fill colour B (fca)

Earthrise uses the colour registers to determine what value to write to vram. The colour to display is looked up in the [CLUT](../hardware/mem/docs/clut.md).

By default, colour registers are set to 1 (one), this avoids users accidentally drawing in colour 0 on a background of 0.

In future, Earthrise may support pattern registers to draw dotted and dashed lines.

## Drawing

**Drawing instructions** use the coordinate and colour registers to draw pixels, lines, and shapes.

A drawing instruction has the **0xD** opcode follow by the function representing a 4-bit shape ID, and up to 8 bits of options.

* pixel (**0xD0**)
    - draw a single pixel at `(x0, y0)`
* line (**0xD1**)
    - draw a line from `(x0, y0)` to `(x1, y1)`
* line fast (**0xDF**) - mnemonic F for fast
    - draw a horizontal line from `x0` to `x1` at vertical position `y0`
    - has faster performance on some hardware, which is especially handy for fills
* circle (**0xD2**)
    - draw a circle with centre `(x0, y0)` and radius `r0` (same reg as `x1`)
    - does nothing if radius is zero or negative
* triangle (**0xD3**)
    - draw a triangle with three vertices `(x0, y0)`, `(x1, y1)`, `(x2, y2)`
* rect (**0xD4**)
    - draw a rect with opposite corners `(x0, y0)` and `(x1, y1)`

Drawing instructions leave coordinate and colour registers untouched.

### Drawing Options

Use up to 8 bits in the instruction to control drawing. Only _filled_ and _colour_ are currently supported.

* Bit 0 - **Filled**
    - (0=outline, 1=fill) - line and pixel use fill colour if this option is used, but draw as for outline
* Bit 1 - **Colour**
    - (0=A, 1=B) - selects line or fill colour as appropriate
* Bit 2 - **Pattern** (0=solid, 1=pattern) - **future feature**
    - Details to follow when pattern is implemented
* Bit 3 - **Edge Style** (0=complete, 1=connect) - **future feature**
    - Connect has missing edges so one line/shape is responsible for each line
    - Top-left rule for filled triangles/rects with connect set
    - First but not last pixel for lines with connect set
        - the diamond-exit rule is more complex and counterintuitive at times
    - Does not apply to circles
* Bit 4 - **Shape option** - extra shape-specific option - **future feature**
    - circle - (0=circle, 1=arc/sector) - arc/sector uses angle registers

Earthrise ensures outline and filled shapes are aligned; an outline triangle will precisely match the edges of a filled triangle with the same coordinates.

You need two instructions to draw a shape with outline and fill, but you get to reuse the coordinates. For example, drawing an outline triangle takes 7 instructions (including 6 coordinate instructions), while an outlined and filled triangle takes one more instruction (8 in total). The draw outline instruction needs to follow the draw filled instruction, otherwise the fill will cover the outline.

## Control Instructions

**Control instructions** share opcode with colour registers, but use letters A-F for the second nibble.

* nop (**0xCC00**) - no operations; mnemonic **C**ontinue
* stop (**0xCE00**) - mnemonic **CE**ase

Add a STOP instruction at the end of your Earthrise drawing, otherwise Earthrise will keep executing instructions until it gets to the end of its command list.

I intend to add jump and return instructions for limited flow control depending on a frame counter.

## Assembler Mnemonics

The Earthrise assembler [erasm](../tools/erasm/), converts instruction mnemonics into hexadecimal instructions. The assembler is written in Python for running on an external computer.

For coordinate registers, specify the name of the register and the signed immediate to load in decimal or hexadecimal. Valid immediates are in the range -2048 to 2047. Possible registers: `x0, y0, x1, y1, x2, y2, x3, y3, xt, yt`.

* `x0 21`
* `y0 -1`
* `xt 255`

Colour registers work in a similar way, but immediates are unsigned in the range 0-255. Possible registers: `lca, lcb, fca, fcb`.

* `lca 5`
* `fcb 0xA`

Drawing (colour):

* `draw pix cb` - pixel (lcb - line colour B)
* `draw line ca` - line (lca)
* `draw circ cb` - outline circle (lcb)
* `draw circf cb` - filled circle (fcb - fill colour B)
* `draw tri ca` - outline triangle (lca)
* `draw trif ca` - filled triangle (fca)
* `draw rect cb` - outline rect (lcb)
* `draw rectf cb` - filled rect (fcb)
* `draw fline cb` - fast line (lcb)

The assembler uses **#** to begin comments.

## Instruction Examples

The following examples demonstrate each of the opcodes and shapes.

### Colours

Set all the line and fill colours as you like. For these examples I'll use:

```
0xC00A  // line colour A = 0xA
0xC108  // line colour B = 0x8
0xC204  // fill colour A = 0x4
0xC305  // fill colour B = 0x5
```

### Pixel

Draw a pixel at (8, 4):

```
0x0008  // x0 =   8
0x1004  // y0 =   4
0xD000  // draw pixel (line colour A)
```

### Line

Draw a line between (8, 16) and (16, 24):

```
0x0008  // x0 =   8
0x1010  // y0 =  16
0x2010  // x1 =  16
0x3018  // x2 =  24
0xD100  // draw line (line colour A)
```

Draw a line between (8, 16) and (16, 24) and (8, 32):

```
0x0008  // x0 =   8
0x1010  // y0 =  16
0x2010  // x1 =  16
0x3018  // y1 =  24
0xD100  // draw line (line colour A)

// use existing values of x0, x1, and y1
0x1020  // y0 =  32
0xD102  // draw line (line colour B)
```

Notice how we could reuse coordinate registers.

### Circle

Draw a filled circle at (160, 88) with radius 64:

```
0x00A0  // x0 = 160
0x1058  // y0 =  88
0x2040  // r0 =  64
0xD201  // draw filled circle
```

Draw a filled circle with an outline at (160, 88) with radius 64:

```
0x00A0  // x0 = 160
0x1058  // y0 =  88
0x2040  // r0 =  64
0xD201  // draw filled circle
0xD200  // draw outline circle (uses same coordinates)
```

You need to draw the outline after the filled version, otherwise the fill will cover the outline.

### Triangle

Draw an outline and filled triangle with vertices (60, 20), (280, 80), and (160, 164) in B colours:

```
0x003C  // x0 =   60
0x1014  // y0 =   20
0x2118  // x1 =  280
0x3050  // y1 =   80
0x40A0  // x2 =  160
0x50A4  // y2 =  164
0xD303  // draw filled triangle (colour B)
0xD302  // draw outline triangle (colour B)
```

### Rect

Draw a filled rect with outline between (16,64) and (44,92):

```
0x0010  // x0 =  16
0x1040  // y0 =  64
0x202C  // x1 =  44
0x305C  // y1 =  92
0xD401  // draw filled rect
0xD400  // draw outline rect
```

### Quad

There isn't a quad instruction (at least for now). You can create an outline quad with four lines and a filled quad with two triangles.

Here's a filled diamond. We keep the common coordinates unchanged, which minimises the number of instructions required.

```
0x0010  // x0 =  16
0x1080  // y0 = 128
0x2010  // x1 =  16
0x3090  // y1 = 144
0x4008  // x2 =   8
0x5088  // y2 = 136
0xD301  // draw filled triangle (colour A)
0x4018  // x2 =  24
0x5088  // y2 = 136
0xD301  // draw filled triangle (colour A)
```

In this case, `y2` was the same for both triangles because the diamond shape is symmetrical but this isn't generally true.

### Stopping

I recommend adding a STOP instruction at the end of your Earthrise instructions.

```
0xCE00  // STOP - mnemonic CEase
```

Otherwise, Earthrise keeps executing until it reaches the end of the command list.
