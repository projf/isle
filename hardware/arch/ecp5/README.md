# Isle ECP5 Modules

| Module                           | Reference                  | Book Chapter | Description                                |
| -------------------------------- | -------------------------- | ------------ | ------------------------------------------ |
| [clock_gen](clock_gen.v)         | -                          | 2D Drawing   | Generate clock with EHXPLL                 |
| [clock2_gen](clock2_gen.v)       | -                          | Display      | Generate two clocks with EHXPLL (for TMDS) |
| [dvi_generator](dvi_generator.v) | -                          | Display      | DVI output via ODDRX1F                     |

There is a Project F blog post covering [ECP5 FPGA Clock Generation](http://projectf.io/posts/ecp5-fpga-clock/).

These architecture-specific modules are simple wrappers around ECP5 primitives. They don't have published docs or tests as yet.
