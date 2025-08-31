// Isle.Computer - Chapter 2: Verilator Top
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module top_ch02 #(
    parameter BPC=5,           // system bits per colour channel
    parameter BPC_BOARD=8,     // board bits per colour channel
    parameter CORDW=16,        // signed coordinate width (bits)
    parameter DISPLAY_MODE=3,  // display mode 3: 672x384 (25 MHz)
    parameter BG_COLR='h0886   // background colour (RGB555)
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

    // 672x384 display with 336x192 4-bit canvas (crocus test)
    localparam FILE_BMAP="../../res/bitmap/crocus/crocus-336x192.mem";
    localparam FILE_PAL="../../res/bitmap/crocus/crocus-336x192_palette.mem";
    localparam CANV_BPP=4;           // bits per pixel (4=16 colour)
    localparam CANV_SCALE=16'd2;     // scaling factor
    localparam WIN_WIDTH=16'd672;    // window width (pixel)
    localparam WIN_HEIGHT=16'd384;   // window height (lines)
    localparam WIN_STARTX=16'd0;     // window horizontal position (pixels)
    localparam WIN_STARTY=16'd0;     // window vertical position (lines)

    // 672x384 display with 672x384 2-bit canvas (latency test)
    // localparam FILE_BMAP="../../res/bitmap/latency/latency.mem";
    // localparam FILE_PAL="../../res/bitmap/latency/latency_palette.mem";
    // localparam CANV_BPP=2;           // bits per pixel (2=4 colour)
    // localparam CANV_SCALE=16'd1;     // scaling factor
    // localparam WIN_WIDTH=16'd672;    // window width (pixel)
    // localparam WIN_HEIGHT=16'd384;   // window height (lines)
    // localparam WIN_STARTX=16'd0;     // window horizontal position (pixels)
    // localparam WIN_STARTY=16'd0;     // window vertical position (lines)


    // colour channel width adjustment for board display
    //   NB. this logic must be updated if you change BPC or BPC_Board
    wire [BPC-1:0] disp_r, disp_g, disp_b;
    always @(*) begin  // 5 to 8-bits per channel (BPC to BPC_Board)
        /* verilator lint_off WIDTHEXPAND */
        sdl_r = (disp_r << 3) | (disp_r >> 2);
        sdl_g = (disp_g << 3) | (disp_g >> 2);
        sdl_b = (disp_b << 3) | (disp_b >> 2);
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
        .disp_x(sdl_x),
        .disp_y(sdl_y),
        .disp_hsync(),
        .disp_vsync(),
        .disp_de(sdl_de),
        .disp_frame(sdl_frame),
        .disp_r(disp_r),
        .disp_g(disp_g),
        .disp_b(disp_b)
    );
endmodule
