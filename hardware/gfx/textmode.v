// Isle.Computer - Textmode with Internal Glyph ROM
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module textmode #(
    parameter CORDW=0,         // signed coordinate width (bits)
    parameter WORD=0,          // machine word size (bits)
    parameter ADDRW=0,         // tram address width (bits)
    parameter CIDXW=0,         // colour index width (bits)
    parameter CLUT_LAT=0,      // CLUT latency (cycles)
    parameter FILE_FONT="",    // font glyph ROM file
    parameter FONT_COUNT=0,    // number of glyphs in font ROM
    parameter GLYPH_HEIGHT=0,  // glyph height (pixels)
    parameter GLYPH_WIDTH=0,   // half-width glyph width (pixels)
    parameter TRAM_DEPTH=0,    // tram depth (chars)
    parameter TRAM_LAT=0       // tram latency (cycles)
    ) (
    input  wire clk_pix,                       // pixel clock
    input  wire rst_pix,                       // reset in pixel clock domain
    input  wire frame_start,                   // frame start flag
    input  wire signed [CORDW-1:0] dx, dy,     // display position
    input  wire [ADDRW-1:0] scroll_offs,       // tram address offset for scroll
    input  wire signed [ADDRW-1:0] text_hres,  // text width (chars)
    input  wire signed [ADDRW-1:0] text_vres,  // text height (chars)
    input  wire [2*CORDW-1:0] win_start,       // text window start coords
    input  wire [2*CORDW-1:0] win_end,         // text window end coords
    input  wire [2*CORDW-1:0] scale,           // text mode scale
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [WORD-1:0] tram_data,          // character data - [23:21] unused
    /* verilator lint_on UNUSEDSIGNAL */
    output reg  [ADDRW-1:0] tram_addr,         // tram address (word)
    output reg  [CIDXW-1:0] pix,               // pixel colour index
    output reg  paint                          // text mode painting enable
    );

    localparam UCPW    = 21;  // Unicode code point width (bits)
    localparam PIX_LAT =  1;  // 1 cycle to register `pix`

    // separate y and x from text window signals
    reg signed [CORDW-1:0] win_start_y, win_start_x;
    reg signed [CORDW-1:0] win_end_y, win_end_x;
    reg [CORDW-1:0] scale_y, scale_y0, scale_x, scale_x0;
    always @(*) begin
        {win_start_y, win_start_x} = win_start;
        {win_end_y, win_end_x} = win_end;
        {scale_y0, scale_x0} = scale;
        scale_x = (scale_x0 == 0) ? 1 : scale_x0;  // if scale is 0, set to 1
        scale_y = (scale_y0 == 0) ? 1 : scale_y0;
    end

    // paint area defined by window
    wire win_y = (dy >= win_start_y) && (dy < win_end_y);
    always @(posedge clk_pix) begin
        paint <= (dx >= win_start_x-1) && (dx < win_end_x-1) && win_y;  // -1 for registering
    end

    // draw start depends on window and latency
    wire signed [CORDW-1:0] draw_start_x = win_start_x - PIX_LAT - CLUT_LAT;

    // glyph end signals
    /* verilator lint_off WIDTHEXPAND */
    wire glyph_x_end = (gx == GLYPH_WIDTH-1  && cnt_x == scale_x-1);
    wire glyph_y_end = (gy == GLYPH_HEIGHT-1 && cnt_y == scale_y-1);
    /* verilator lint_on WIDTHEXPAND */

    // bit widths
    localparam GLYPH_HEIGHT_W = $clog2(GLYPH_HEIGHT);
    localparam GLYPH_WIDTH_W  = $clog2(GLYPH_WIDTH);

    // character properties
    reg [UCPW-1:0]  ucp;      // Unicode code point
    reg [CIDXW-1:0] colr_fg;  // foreground colour
    reg [CIDXW-1:0] colr_bg;  // background colour

    // position within tram but constrained to text display area
    reg [ADDRW-1:0] tx;  // 0 to text_hres-1
    reg [ADDRW-1:0] ty;  // 0 to text_vres-1

    // position within character glyph
    reg [GLYPH_WIDTH_W-1:0]  gx;  // 0 to GLYPH_WIDTH-1
    reg [GLYPH_HEIGHT_W-1:0] gy;  // 0 to GLYPH_HEIGHT-1

    // scale counters
    reg [CORDW-1:0] cnt_x, cnt_y;

    wire [GLYPH_WIDTH-1:0] pix_line;  // line of pixels from ROM
    reg [GLYPH_WIDTH-1:0] pix_line_reg;  // copy of line of pixels
    reg [ADDRW-1:0] tram_addr_line;  // addr copy, so we can return to it at line start

    // state machine
    localparam IDLE       = 0;  // idle awaiting 'frame_start'
    localparam INIT       = 1;  // frame init
    localparam AWAIT      = 2;  // await start of rendering
    localparam DRAW       = 3;  // draw pixels
    localparam CHR_LINE   = 4;  // for new character line
    localparam SCR_LINE   = 5;  // for new screen line

    localparam STATEW = 3;  // state width (bits)
    reg [STATEW-1:0] state;

    always @(posedge clk_pix) begin
        case (state)
            INIT: begin
                if (dy == win_start_y) state <= AWAIT;
                tram_addr <= scroll_offs;
                tram_addr_line <= scroll_offs;
                tx <= 0;
                ty <= 0;
                gx <= 0;
                gy <= 0;
                cnt_x <= 0;
                cnt_y <= 0;
            end
            AWAIT: begin
                if (dx == draw_start_x - 1) state <= DRAW;  // -1 for transition to DRAW
                colr_fg <= tram_data[WORD-CIDXW-1:WORD-2*CIDXW];
                colr_bg <= tram_data[WORD-1:WORD-CIDXW];
                pix_line_reg <= pix_line;
                ucp <= tram_data[UCPW-1:0];
            end
            DRAW: begin
                if (tx == text_hres || dx >= win_end_x-1) begin
                    if (ty == text_vres || dy >= win_end_y-1) state <= IDLE;
                    else if (glyph_y_end) state <= CHR_LINE;
                    else state <= SCR_LINE;
                end

                // step through horizontal pixels
                if (cnt_x == scale_x-1) begin
                    cnt_x <= 0;
                    /* verilator lint_off WIDTHEXPAND */
                    gx <= (gx == GLYPH_WIDTH-1) ? 0 : gx + 1;
                    /* verilator lint_on WIDTHEXPAND */
                end else cnt_x <= cnt_x + 1;

                if (gx == 0 && cnt_x == 0)
                    tram_addr <= (tram_addr == TRAM_DEPTH-1) ? scroll_offs : tram_addr + 1;

                // register Unicode code point; TRAM_LAT+1 to reg tram_addr
                if (gx == TRAM_LAT+1 && cnt_x == 0) ucp <= tram_data[UCPW-1:0];

                // register glyph pixels and colours at end of current glyph
                if (glyph_x_end) begin
                    colr_fg <= tram_data[WORD-CIDXW-1:WORD-2*CIDXW];
                    colr_bg <= tram_data[WORD-1:WORD-CIDXW];
                    pix_line_reg <= pix_line;
                    tx <= tx + 1;
                end
            end
            CHR_LINE: begin  // prepare for next line of chars
                state <= SCR_LINE;
                tram_addr_line <= tram_addr_line + text_hres;  // address for next line of chars
                ty <= ty + 1;  // move down to next line of chars
            end
            SCR_LINE: begin  // new line of pixels
                state <= AWAIT;

                // set tram address to start of line
                if (tram_addr_line > TRAM_DEPTH-1) begin // handle wrapping
                    tram_addr <= tram_addr_line - TRAM_DEPTH;
                    tram_addr_line <= tram_addr_line - TRAM_DEPTH;
                end else tram_addr <= tram_addr_line;

                // begin with first char on line; reset horizontal position
                tx <= 0;
                gx <= 0;
                cnt_x <= 0;

                // step through lines (vertical pixels)
                if (cnt_y == scale_y-1) begin
                    cnt_y <= 0;
                    /* verilator lint_off WIDTHEXPAND */
                    gy <= (gy == GLYPH_HEIGHT-1) ? 0 : gy + 1;
                    /* verilator lint_on WIDTHEXPAND */
                end else cnt_y <= cnt_y + 1;
            end
            default: begin  // IDLE
                if (frame_start) state <= INIT;
            end
        endcase

        if (rst_pix) state <= IDLE;
    end

    // output text pixels - text pixel enable controlled by paint signal
    always @(posedge clk_pix) pix <= pix_line_reg[gx] ? colr_fg : colr_bg;

    font_glyph #(
        .FONT_COUNT(FONT_COUNT),
        .FILE_FONT(FILE_FONT),
        .HEIGHT(GLYPH_HEIGHT),
        .UCPW(UCPW),
        .WIDTH(GLYPH_WIDTH)
    ) font_glyph_instance (
        .clk(clk_pix),
        .ucp(ucp),
        .line_id(gy),
        .pix_line(pix_line)
    );
endmodule
