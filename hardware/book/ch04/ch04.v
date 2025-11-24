// Isle.Computer - Chapter 4: Text Mode
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module ch04 #(
    parameter BPC=5,            // bits per colour channel
    parameter CORDW=16,         // signed coordinate width (bits)
    parameter DISPLAY_MODE=0,   // display mode (see display.v for modes)
    parameter BG_COLR=0,        // background colour (RGB555)
    parameter FILE_FONT="",     // font glyph ROM file
    parameter FILE_PAL="",      // initial palette for CLUT
    parameter FILE_TXT="",      // initial text file for tram
    parameter FONT_COUNT=128,   // number of glyphs in font ROM
    parameter TEXT_SCALE=16'h1  // text mode scale
    ) (
    input  wire clk_sys,                    // system clock
    input  wire clk_pix,                    // pixel clock (used by display)
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire rst_sys,                    // reset (system clock domain)
    /* verilator lint_on UNUSEDSIGNAL */
    input  wire rst_pix,                    // reset (pixel clock domain)
    output reg  signed [CORDW-1:0] disp_x,  // horizontal display position
    output reg  signed [CORDW-1:0] disp_y,  // vertical display position
    output reg  disp_hsync,                 // horizontal display sync
    output reg  disp_vsync,                 // vertical display sync
    output reg  disp_de,                    // display data enable
    output reg  disp_frame,                 // high for one cycle at frame start
    output reg  [BPC-1:0] disp_r,           // red display channel
    output reg  [BPC-1:0] disp_g,           // green display channel
    output reg  [BPC-1:0] disp_b            // blue display channel
    );

    `define DEBUG  // debug messages in simulation (comment out to disable)

    // text mode
    localparam TEXT_CIDXW =  4;  // 16 colours available in textmode
    localparam TRAM_ADDRW = 11;  // tram address width (bits)
    localparam TRAM_HRES  = 84;  // tram width (chars) - 84x8 = 672
    localparam TRAM_VRES  = 24;  // tram height (chars) - 24x16 = 384

    // internal system params
    localparam WORD = 32;  // machine word size (bits)
    localparam BYTE =  8;  // machine byte size (bits)
    localparam BYTE_CNT = WORD / BYTE;  // bytes in word (for write enable)
    localparam CIDX_ADDRW = 8;   // colour index address width 2^8 = 256 colours
    localparam COLRW = 3 * BPC;  // colour width across three channels (bits)

    // display signals
    wire signed [CORDW-1:0] dx, dy;
    wire hsync, vsync, de;
    wire frame_start, line_start;


    //
    // Text Mode RAM (tram)
    //

    wire [TRAM_ADDRW-1:0] tram_addr_disp;
    wire [WORD-1:0] tram_dout_disp;

    // should adjust based on display mode (fixed at size of tram for now)
    reg signed [CORDW-1:0] text_hres = TRAM_HRES;
    reg signed [CORDW-1:0] text_vres = TRAM_VRES;

    tram #(
        .BYTE(BYTE),
        .BYTE_CNT(BYTE_CNT),
        .WORD(WORD),
        .ADDRW(TRAM_ADDRW),
        .FILE_TXT(FILE_TXT)
    ) tram_inst (
        .clk_sys(clk_sys),
        .clk_pix(clk_pix),
        /* verilator lint_off PINCONNECTEMPTY */
        .we_sys(),  // for future CPU use
        .addr_sys(),
        .addr_disp(tram_addr_disp),
        .din_sys(),
        .dout_sys(),
        .dout_disp(tram_dout_disp)
        /* verilator lint_on PINCONNECTEMPTY */
    );


    //
    // Text Mode
    //

    localparam TEXT_LAT = 4;  // text display latency

    reg [TRAM_ADDRW-1:0] text_offs = 0;  // start display with this char (word)
    wire [TEXT_CIDXW-1:0] text_pix;
    wire paint_text;  // enable text paint
    textmode #(
        .CORDW(CORDW),
        .WORD(WORD),
        .ADDRW(TRAM_ADDRW),
        .CIDXW(TEXT_CIDXW),
        .FILE_FONT(FILE_FONT),
        .FONT_COUNT(FONT_COUNT),
        .TEXT_LAT(TEXT_LAT),
        .TRAM_HRES(TRAM_HRES),
        .TRAM_VRES(TRAM_VRES)
    ) textmode_inst (
        .clk(clk_pix),
        .rst(rst_pix),
        .start(line_start && dy==0),
        .scroll_offs(text_offs),
        .dx(dx),
        .dy(dy),
        .text_hres(text_hres),
        .text_vres(text_vres),
        .scale({TEXT_SCALE, TEXT_SCALE}),
        .tram_data(tram_dout_disp),
        .tram_addr(tram_addr_disp),
        .pix(text_pix),
        .paint_text(paint_text)
    );


    //
    // CLUT
    //

    reg  [CIDX_ADDRW-1:0] clut_addr_disp;
    wire [COLRW-1:0] clut_dout_disp;

    clut #(
        .ADDRW(CIDX_ADDRW),
        .DATAW(COLRW),
        .FILE_PAL(FILE_PAL)
    ) clut_inst (
        .clk_sys(clk_sys),
        .clk_pix(clk_pix),
        /* verilator lint_off PINCONNECTEMPTY */
        .we_sys(),  // for future CPU use
        .addr_sys(),
        .din_sys(),
        .dout_sys(),
        /* verilator lint_on PINCONNECTEMPTY */
        .addr_disp(clut_addr_disp),
        .dout_disp(clut_dout_disp)
    );


    //
    // Display Controller
    //

    display #(
        .CORDW(CORDW),
        .MODE(DISPLAY_MODE)
    ) display_inst (
        .clk_pix(clk_pix),
        .rst_pix(rst_pix),
        /* verilator lint_off PINCONNECTEMPTY */
        .hres(),
        .vres(),
        /* verilator lint_on PINCONNECTEMPTY */
        .dx(dx),
        .dy(dy),
        .hsync(hsync),
        .vsync(vsync),
        .de(de),
        .frame_start(frame_start),
        .line_start(line_start)
    );


    //
    // Painting & Display Output
    //

    assign clut_addr_disp = {4'b0, text_pix};  // should use params

    reg [BPC-1:0] paint_r, paint_g, paint_b;
    always @(*) {paint_r, paint_g, paint_b} = paint_text ? clut_dout_disp : BG_COLR;

    // register display signals
    always @(posedge clk_pix) begin
        disp_x <= dx;
        disp_y <= dy;
        disp_hsync <= hsync;
        disp_vsync <= vsync;
        disp_de <= de;
        disp_frame <= frame_start;
        disp_r <= (de) ? paint_r : 'h0;  // paint colour but black in blanking
        disp_g <= (de) ? paint_g : 'h0;
        disp_b <= (de) ? paint_b : 'h0;
    end
endmodule
