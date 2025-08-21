// Isle.Computer - Chapter 2: Lakritz Top
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module top_ch02 #(
    parameter BPC=5,           // system bits per colour channel
    parameter BPC_BOARD=8,     // board bits per colour channel
    parameter CORDW=16,        // signed coordinate width (bits)
    parameter DISPLAY_MODE=2,  // display mode 2: 1366x768 (72 MHz)
    parameter BG_COLR='h0886   // background colour (RGB555)
    ) (
    input  wire clk_48m,       // 48 MHz board clock
    output wire [3:0] ddmi_dp  // DVI out
    );

    // 1366x768 display with 336x192 4-bit canvas (crocus test)
    localparam FILE_BMAP="../../res/bitmap/crocus/crocus-336x192.mem";
    localparam FILE_PAL="../../res/bitmap/crocus/crocus-336x192_palette.mem";
    localparam CANV_BPP=4;          // bits per pixel (4=16 colour)
    localparam CANV_SCALE=16'd4;    // scaling factor
    localparam WIN_WIDTH=16'd1344;  // window width (pixel)
    localparam WIN_HEIGHT=16'd768;  // window height (lines)
    localparam WIN_STARTX=16'd11;   // window horizontal position (pixels)
    localparam WIN_STARTY=16'd0;    // window vertical position (lines)

    // 1366x768 display with 672x384 2-bit canvas (latency test)
    // localparam FILE_BMAP="../../res/bitmap/latency/latency.mem";
    // localparam FILE_PAL="../../res/bitmap/latency/latency_palette.mem";
    // localparam CANV_BPP=2;          // bits per pixel (2=4 colour)
    // localparam CANV_SCALE=16'd2;    // scaling factor
    // localparam WIN_WIDTH=16'd1344;  // window width (pixel)
    // localparam WIN_HEIGHT=16'd768;  // window height (lines)
    // localparam WIN_STARTX=16'd11;   // window horizontal position (pixels)
    // localparam WIN_STARTY=16'd0;    // window vertical position (lines)


    // generate common clock - 72 MHz for 1366x768 (DISPLAY_MODE=2)
    // 48 MHz -> 360/72 MHz
    wire clk, clk_5x, clk_locked;
    clock2_gen #(
        .CLKI_DIV(2),
        .CLKFB_DIV(15),
        .CLKOP_DIV(2),
        .CLKOP_CPHASE(1),
        .CLKOS_DIV(10),
        .CLKOS_CPHASE(5)
    ) clock2_gen_inst (
       .clk_in(clk_48m),
       .clk_5x_out(clk_5x),
       .clk_out(clk),
       .clk_locked(clk_locked)
    );

    reg rst;  // sync reset from clock lock
    always @(posedge clk) rst <= !clk_locked;  // wait for clock lock

    // display signals for TMDS encoding
    wire disp_hsync, disp_vsync, disp_de;

    // colour channel width adjustment for board display
    //   NB. this logic must be updated if you change BPC or BPC_Board
    wire [BPC-1:0] disp_r, disp_g, disp_b;
    reg [BPC_BOARD-1:0] board_r, board_g, board_b;
    always @(*) begin  // 5 to 8-bits per channel (BPC to BPC_Board)
        /* verilator lint_off WIDTHEXPAND */
        board_r = (disp_r << 3) | (disp_r >> 2);
        board_g = (disp_g << 3) | (disp_g >> 2);
        board_b = (disp_b << 3) | (disp_b >> 2);
        /* verilator lint_on WIDTHEXPAND */
    end


    ch02 #(
        .BPC(BPC),
        .CORDW(CORDW),
        .DISPLAY_MODE(DISPLAY_MODE),
        .BG_COLR(BG_COLR),
        .FILE_BMAP(FILE_BMAP),
        .FILE_PAL(FILE_PAL),
        .CANV_SCALE(CANV_SCALE),
        .CANV_BPP(CANV_BPP),
        .WIN_WIDTH(WIN_WIDTH),
        .WIN_HEIGHT(WIN_HEIGHT),
        .WIN_STARTX(WIN_STARTX),
        .WIN_STARTY(WIN_STARTY)
    ) ch02_inst (
        .clk(clk),
        .rst(rst),
        /* verilator lint_off PINCONNECTEMPTY */
        .disp_x(),
        .disp_y(),
        /* verilator lint_on PINCONNECTEMPTY */
        .disp_hsync(disp_hsync),
        .disp_vsync(disp_vsync),
        .disp_de(disp_de),
        /* verilator lint_off PINCONNECTEMPTY */
        .disp_frame(),
        /* verilator lint_on PINCONNECTEMPTY */
        .disp_r(disp_r),
        .disp_g(disp_g),
        .disp_b(disp_b)
    );

    // TMDS encoding and serialization
    dvi_generator dvi_out (
        .clk_pix(clk),
        .clk_pix_5x(clk_5x),
        .rst_pix(rst),
        .de(disp_de),
        .ch0_din(board_b),
        .ch1_din(board_g),
        .ch2_din(board_r),
        .ch0_ctrl({disp_vsync, disp_hsync}),
        .ch1_ctrl(2'b00),
        .ch2_ctrl(2'b00),
        .ch0_dout(ddmi_dp[0]),
        .ch1_dout(ddmi_dp[1]),
        .ch2_dout(ddmi_dp[2]),
        .clk_dout(ddmi_dp[3])
    );
endmodule
