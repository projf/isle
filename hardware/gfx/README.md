# Isle Graphics Hardware

| Module                           | Reference                    | Book Chapter    | Description                              |
| -------------------------------- | ---------------------------- | --------------- | ---------------------------------------- |
| [canv_disp_agu](canv_disp_agu.v) | [doc](docs/canv_disp_agu.md) | Bitmap Graphics | Canvas display address generation        |
| [display](display.v)             | [doc](docs/display.md)       | Display         | Display controller                       |
| [tmds_encoder](tmds_encoder.v)   | [doc](docs/tmds_encoder.md)  | Display         | TMDS Encoder (DVI)                       |

See [Verilog Tests](../../docs/verilog-tests.md) for advice on setting up the test environment and running tests.

NB. The TMDS encoder test uses Verilator.
