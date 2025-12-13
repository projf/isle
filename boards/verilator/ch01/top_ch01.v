// Isle.Computer - Chapter 1: Verilator Top
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module top_ch01 #(
    parameter BPC=5,          // system bits per colour channel
    parameter BPC_BOARD=8,    // board bits per colour channel
    parameter CORDW=16,       // signed coordinate width (bits)
    parameter DISPLAY_MODE=0  // display mode 0: 640x480 (25.2 MHz)
    ) (
    input  wire clk,                      // sim clock
    input  wire rst,                      // sim reset
    output reg signed [CORDW-1:0] sdl_x,  // horizontal SDL position
    output reg signed [CORDW-1:0] sdl_y,  // vertical SDL position
    output reg sdl_de,                    // data enable (low in blanking interval)
    output reg sdl_frame,                 // high for one cycle at frame start
    output reg [BPC_BOARD-1:0] sdl_r,     // red video channel
    output reg [BPC_BOARD-1:0] sdl_g,     // green video channel
    output reg [BPC_BOARD-1:0] sdl_b      // blue video channel
    );

    // colour channel width adjustment for board display
    // NB. this logic must be updated if you change BPC or BPC_Board
    wire [BPC-1:0] disp_r, disp_g, disp_b;
    always @(*) begin  // 5 to 8-bits per channel (BPC to BPC_Board)
        /* verilator lint_off WIDTHEXPAND */
        sdl_r = (disp_r << 3) | (disp_r >> 2);
        sdl_g = (disp_g << 3) | (disp_g >> 2);
        sdl_b = (disp_b << 3) | (disp_b >> 2);
        /* verilator lint_on WIDTHEXPAND */
    end

    // use ch01_square, ch01_pattern, or starfield
    ch01_square #(
        .BPC(BPC),
        .CORDW(CORDW),
        .DISPLAY_MODE(DISPLAY_MODE)
    ) ch01_inst (
        .clk(clk),
        .rst(rst),
        .disp_x(sdl_x),
        .disp_y(sdl_y),
        /* verilator lint_off PINCONNECTEMPTY */
        .disp_hsync(),
        .disp_vsync(),
        /* verilator lint_on PINCONNECTEMPTY */
        .disp_de(sdl_de),
        .disp_frame(sdl_frame),
        .disp_r(disp_r),
        .disp_g(disp_g),
        .disp_b(disp_b)
    );
endmodule
