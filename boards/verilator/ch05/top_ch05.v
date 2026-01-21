// Isle.Computer - Chapter 5: Verilator Top
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module top_ch05 #(
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

    localparam SW = "../../../software";  // software binary path
    localparam RES = "../../../res";  // resource path

    // software params
    localparam FILE_SOFT = {SW, "/book/ch05/hello.mem"};

    // text mode params
    localparam FILE_PAL   = {RES, "/palettes/go-16.mem"};
    localparam FILE_TXT   = "";
    localparam TEXT_SCALE = 32'h00010001;  // text scaling factor 'hYYYYXXXX
    localparam WIN_START  = 32'h00000000;  // text window start coords
    localparam WIN_END    = 32'h018002A0;  // text window end coords

    // font params
    localparam FILE_FONT    = {RES, "/fonts/unifont-rom.mem"};
    localparam FONT_COUNT   = 128;  // glyphs in FILE_FONT
    localparam GLYPH_HEIGHT =  16;  // glyph height (pixels)
    localparam GLYPH_WIDTH  =   8;  // half-width glyph width (pixels)

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

    ch05 #(
        .BPC(BPC),
        .CORDW(CORDW),
        .DISPLAY_MODE(DISPLAY_MODE),
        .BG_COLR(BG_COLR),
        .FILE_FONT(FILE_FONT),
        .FILE_PAL(FILE_PAL),
        .FILE_SOFT(FILE_SOFT),
        .FILE_TXT(FILE_TXT),
        .FONT_COUNT(FONT_COUNT),
        .GLYPH_HEIGHT(GLYPH_HEIGHT),
        .GLYPH_WIDTH(GLYPH_WIDTH),
        .TEXT_SCALE(TEXT_SCALE),
        .WIN_START(WIN_START),
        .WIN_END(WIN_END)
    ) ch05_inst (
        .clk_sys(clk),  // common system and pixel clock in simulation
        .clk_pix(clk),
        .rst_sys(rst),
        .rst_pix(rst),
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
