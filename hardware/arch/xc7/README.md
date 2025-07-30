# Isle XC7 Modules

| Module                           | Reference                  | Book Chapter | Description                                     |
| -------------------------------- | -------------------------- | ------------ | ----------------------------------------------- |
| [clock2_gen](clock2_gen.v)       | -                          | Display      | Generate two clocks with MMCME2_BASE (for TMDS) |
| [dvi_generator](dvi_generator.v) | -                          | Display      | DVI output using oserdes_10b                    |
| [oserdes_10b](oserdes_10b.v)     | -                          | Display      | 10:1 Output Serializer with OSERDESE2           |
| [tmds_out](tmds_out.v)           | -                          | Display      | TMDS Signal Output with OBUFDS                  |

These architecture-specific modules are simple wrappers around XC7 primitives. They don't have published docs or tests as yet.
