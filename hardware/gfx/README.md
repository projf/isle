# Isle Graphics Hardware

| Module                           | Reference                    | Book Chapter    | Description                              |
| -------------------------------- | ---------------------------- | --------------- | ---------------------------------------- |
| [canv_disp_agu](canv_disp_agu.v) | [doc](docs/canv_disp_agu.md) | Bitmap Graphics | Canvas display address generation        |
| [canv_draw_agu](canv_draw_agu.v) | [doc](docs/canv_draw_agu.md) | 2D Drawing      | Canvas draw address generation           |
| [circle](circle.v)               | [doc](docs/circle.md)        | 2D Drawing      | Draw circle                              |
| [display](display.v)             | [doc](docs/display.md)       | Display         | Display controller                       |
| [earthrise](earthrise.v)         | [doc](docs/earthrise.md)     | 2D Drawing      | Earthrise drawing engine                 |
| [fline](fline.v)                 | [doc](docs/fline.md)         | 2D Drawing      | Draw fast (horizontal) line              |
| [line](line.v)                   | [doc](docs/line.md)          | 2D Drawing      | Draw line                                |
| [tmds_encoder](tmds_encoder.v)   | [doc](docs/tmds_encoder.md)  | Display         | TMDS Encoder (DVI)                       |

See [Verilog Tests](../../docs/verilog-tests.md) for advice on setting up the test environment and running tests.

NB. The TMDS encoder test uses Verilator.
