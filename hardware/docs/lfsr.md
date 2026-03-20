# Linear Feedback Shift Register

The **lfsr** [[verilog src](../math/lfsr.v)] module creates a [Galois linear-feedback shift register](https://en.wikipedia.org/wiki/Linear-feedback_shift_register#Galois_LFSRs), which is ideal for pseudorandom number or noise generation.

The LFSR module is used in the [Starfield](../../projects/starfield) project.

## What's a LFSR?

An LFSR can create a pseudorandom number sequence in which every number appears just once. For example, an 8-bit LSFR can generate all the numbers from 1-255 in a repeatable sequence that seems random. 

The logic for an LFSR can be written in a single line of Verilog; for example, an 8-bit LFSR:

```verilog
sreg <= {1'b0, sreg[7:1]} ^ (sreg[0] ? 8'b10111000 : 8'b0);
```

The "magic" value `8'b10111000` is known as the taps and controls which bits of the number are XOR'd. Wikipedia has the list of [taps](https://en.wikipedia.org/wiki/Linear-feedback_shift_register#Example_polynomials_for_maximal_LFSRs) for 2-24 bits.

Isle uses a 32-bit LFSR:

```verilog
// 32-bit LFSR (32,22,2,1)
localparam TAPS = 32'b1000_0000_0010_0000_0000_0000_0000_0011;
```

NB. You MUST reset the LFSR before use to initialise the seed (starting value).

## Parameters

* `LEN` - shift register length (bits)
* `TAPS` - XOR taps

## Signals

### Input

* `clk` - clock
* `rst` - reset (must be asserted before use)
* `en` - enable
* `seed` - seed (uses default seed if zero)

### Output

* `sreg` - lfsr output
