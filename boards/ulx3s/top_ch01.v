// Isle.Computer - Chapter 1: ULX3S Top
// Copyright Isle Authors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module top_ch01 #(
    parameter BPC=5,          // system bits per colour channel
    parameter BPC_BOARD=8,    // board bits per colour channel
    parameter CORDW=16,       // signed coordinate width (bits)
    parameter DISPLAY_MODE=0  // display mode 0: 640x480 (25.2 MHz)
    ) (
    input  wire clk_25m,       // 25 MHz board clock
    output wire [3:0] gpdi_dp  // DVI out
    );

    // generate common clock - 25.2 MHz for 640x480 (DISPLAY_MODE=0)
    // 25 MHz -> 126/25.2 MHz
    wire clk, clk_5x, clk_locked;
    clock2_gen #(
        .CLKI_DIV(25),
        .CLKFB_DIV(126),
        .CLKOP_DIV(4),
        .CLKOP_CPHASE(2),
        .CLKOS_DIV(20),
        .CLKOS_CPHASE(10)
    ) clock2_gen_inst (
       .clk_in(clk_25m),
       .clk_5x_out(clk_5x),
       .clk_out(clk),
       .clk_locked(clk_locked)
    );

    reg rst;  // sync reset from clock lock
    always @(posedge clk) rst <= !clk_locked;  // wait for clock lock

    // display signals for TMDS encoding
    wire disp_hsync, disp_vsync, disp_de;

    // colour channel width adjustment for board display
    // NB. this logic must be updated if you change BPC or BPC_Board
    wire [BPC-1:0] disp_r, disp_g, disp_b;
    reg [BPC_BOARD-1:0] board_r, board_g, board_b;
    always @(*) begin  // 5 to 8-bits per channel (BPC to BPC_Board)
        /* verilator lint_off WIDTHEXPAND */
        board_r = (disp_r << 3) | (disp_r >> 2);
        board_g = (disp_g << 3) | (disp_g >> 2);
        board_b = (disp_b << 3) | (disp_b >> 2);
        /* verilator lint_on WIDTHEXPAND */
    end

    // use ch01_square or ch01_pattern
    ch01_square #(
        .BPC(BPC),
        .CORDW(CORDW),
        .DISPLAY_MODE(DISPLAY_MODE)
    ) ch01_inst (
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
        .ch0_dout(gpdi_dp[0]),
        .ch1_dout(gpdi_dp[1]),
        .ch2_dout(gpdi_dp[2]),
        .clk_dout(gpdi_dp[3])
    );
endmodule
