// Isle.Computer - Chapter 4: Nexys Video Top
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module top_ch04 #(
    parameter BPC=5,           // system bits per colour channel
    parameter BPC_BOARD=8,     // board bits per colour channel
    parameter CORDW=16,        // signed coordinate width (bits)
    parameter DISPLAY_MODE=2,  // display mode 2: 1366x768 (72 MHz)
    parameter BG_COLR='h0886   // background colour (RGB555)
    ) (
    input  wire clk_100m,       // 100 MHz clock
    output wire hdmi_tx_ch0_p,  // HDMI source channel 0 diff+
    output wire hdmi_tx_ch0_n,  // HDMI source channel 0 diff-
    output wire hdmi_tx_ch1_p,  // HDMI source channel 1 diff+
    output wire hdmi_tx_ch1_n,  // HDMI source channel 1 diff-
    output wire hdmi_tx_ch2_p,  // HDMI source channel 2 diff+
    output wire hdmi_tx_ch2_n,  // HDMI source channel 2 diff-
    output wire hdmi_tx_clk_p,  // HDMI source clock diff+
    output wire hdmi_tx_clk_n   // HDMI source clock diff-
    );

    localparam RES = "../../../res";  // resource path

    // text mode params
    localparam FILE_PAL   = {RES, "/palettes/go-16.mem"};
    localparam FILE_TXT   = {RES, "/textmaps/rom-84x24.mem"};
    localparam TEXT_SCALE = 32'h00020002;  // text scaling factor 'hYYYYXXXX
    localparam WIN_START  = 32'h0000000B;  // text window start coords
    localparam WIN_END    = 32'h0300054B;  // text window end coords

    // font params
    localparam FILE_FONT    = {RES, "/fonts/system-font-rom.mem"};
    localparam FONT_COUNT   = 128;  // glyphs in FILE_FONT
    localparam GLYPH_HEIGHT =  16;  // glyph height (pixels)
    localparam GLYPH_WIDTH  =   8;  // half-width glyph width (pixels)

    // system clock - 25 MHz
    // 100 MHz -> 25 MHz
    wire clk_sys, clk_sys_locked;
    clock_gen #(
        .MULT_MASTER(9.125),
        .DIV_MASTER(1),
        .DIV_1X(36.5),
        .IN_PERIOD(10.0)
    ) clock_sys_inst (
       .clk_in(clk_100m),
       .clk_out(clk_sys),
       .clk_locked(clk_sys_locked)
    );

    reg rst_sys;  // sync reset from clock lock
    always @(posedge clk_sys) rst_sys <= !clk_sys_locked;  // await clock lock

    // pixel clock - 72 MHz for 1366x768 (DISPLAY_MODE=2)
    // 100 MHz -> 360/72 MHz
    wire clk_pix, clk_pix_5x, clk_pix_locked;
    clock2_gen #(
        .MULT_MASTER(54),
        .DIV_MASTER(5),
        .DIV_5X(3.0),
        .DIV_1X(15),
        .IN_PERIOD(10.0)
    ) clock_pix_inst (
       .clk_in(clk_100m),
       .clk_5x_out(clk_pix_5x),
       .clk_out(clk_pix),
       .clk_locked(clk_pix_locked)
    );

    reg rst_pix;  // sync reset from clock lock
    always @(posedge clk_pix) rst_pix <= !clk_pix_locked;  // await clock lock

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

    ch04 #(
        .BPC(BPC),
        .CORDW(CORDW),
        .DISPLAY_MODE(DISPLAY_MODE),
        .BG_COLR(BG_COLR),
        .FILE_FONT(FILE_FONT),
        .FILE_PAL(FILE_PAL),
        .FILE_TXT(FILE_TXT),
        .FONT_COUNT(FONT_COUNT),
        .GLYPH_HEIGHT(GLYPH_HEIGHT),
        .GLYPH_WIDTH(GLYPH_WIDTH),
        .TEXT_SCALE(TEXT_SCALE),
        .WIN_START(WIN_START),
        .WIN_END(WIN_END)
    ) ch04_inst (
        .clk_sys(clk_sys),
        .clk_pix(clk_pix),
        .rst_sys(rst_sys),
        .rst_pix(rst_pix),
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
    wire ch0_dout, ch1_dout, ch2_dout, clk_dout;
    dvi_generator dvi_out (
        .clk_pix(clk_pix),
        .clk_pix_5x(clk_pix_5x),
        .rst_pix(rst_pix),
        .de(disp_de),
        .ch0_din(board_b),
        .ch1_din(board_g),
        .ch2_din(board_r),
        .ch0_ctrl({disp_vsync, disp_hsync}),
        .ch1_ctrl(2'b00),
        .ch2_ctrl(2'b00),
        .ch0_dout(ch0_dout),
        .ch1_dout(ch1_dout),
        .ch2_dout(ch2_dout),
        .clk_dout(clk_dout)
    );

    // TMDS output pins
    tmds_out tmds_ch0 (.tmds(ch0_dout), .pin_p(hdmi_tx_ch0_p), .pin_n(hdmi_tx_ch0_n));
    tmds_out tmds_ch1 (.tmds(ch1_dout), .pin_p(hdmi_tx_ch1_p), .pin_n(hdmi_tx_ch1_n));
    tmds_out tmds_ch2 (.tmds(ch2_dout), .pin_p(hdmi_tx_ch2_p), .pin_n(hdmi_tx_ch2_n));
    tmds_out tmds_clk (.tmds(clk_dout), .pin_p(hdmi_tx_clk_p), .pin_n(hdmi_tx_clk_n));
endmodule
