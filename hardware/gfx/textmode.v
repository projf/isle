// Isle.Computer - Textmode with Internal Glyph ROM
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module textmode #(
    parameter CORDW=0,       // signed coordinate width (bits)
    parameter WORD=0,        // machine word size (bits)
    parameter ADDRW=0,       // text buffer memory address width (bits)
    parameter CIDXW=0,       // colour index width (bits)
    parameter FILE_FONT="",  // font glyph ROM file
    parameter TEXT_LAT=0,    // text display latency
    parameter TRAM_HRES=0,   // text buffer width (chars)
    parameter TRAM_VRES=0    // text buffer height (chars)
    ) (
    input  wire clk,                           // clock
    input  wire rst,                           // reset
    input  wire start,                         // start text display
    input  wire [ADDRW-1:0] scroll_offs,       // text buffer scroll offset
    input  wire signed [CORDW-1:0] dx, dy,     // display position
    input  wire signed [CORDW-1:0] text_hres,  // text display width (chars)
    input  wire signed [CORDW-1:0] text_vres,  // text display height (chars)
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [WORD-1:0] tram_data,   // char data - we don't use [23:21]
    /* verilator lint_on UNUSEDSIGNAL */
    output reg  [ADDRW-1:0] tram_addr,  // text buffer address
    output reg  [CIDXW-1:0] pix,        // pixel colour index
    output reg  paint_text              // textmode painting enable
    );

    localparam GLYPH_HEIGHT   = 16;  // glyph height (pixels) - must be pow of 2
    localparam GLYPH_WIDTH    =  8;  // singe-width glyph width (pixels)
    localparam UCPW           = 21;  // Unicode code point width (bits)
    localparam LAST_ADDR = TRAM_HRES * TRAM_VRES - 1;  // end of buffer

    // flags
    reg signed [CORDW-1:0] char_line_end;
    reg signed [CORDW-1:0] char_frame_end;

    always @(posedge clk) begin
        char_line_end  <= (GLYPH_WIDTH  * text_hres) - TEXT_LAT;
        char_frame_end <= (GLYPH_HEIGHT * text_vres) - 1;
    end

    // bit widths
    localparam GLYPH_HEIGHT_W = $clog2(GLYPH_HEIGHT);
    localparam GLYPH_WIDTH_W  = $clog2(GLYPH_WIDTH);

    // character properties
    reg [UCPW-1:0]  ucp;      // Unicode code point
    reg [CIDXW-1:0] colr_fg;  // foreground colour
    reg [CIDXW-1:0] colr_bg;  // background colour

    reg [GLYPH_HEIGHT_W-1:0] line_id;
    wire [GLYPH_WIDTH-1:0] pix_line;
    font_glyph #(
        .FILE_FONT(FILE_FONT)
    ) font_glyph_instance (
        .clk(clk),
        .rst(rst),
        .ucp(ucp),
        .line_id(line_id),
        .pix_line(pix_line)
    );

    // position within text buffer
    reg [ADDRW-1:0] tx;
    reg [ADDRW-1:0] ty;

    // position within glyph
    reg [GLYPH_WIDTH_W-1:0]  gx;
    reg [GLYPH_HEIGHT_W-1:0] gy;

    reg [GLYPH_WIDTH-1:0] pix_line_reg;  // copy of glyph pixel line
    reg [ADDRW-1:0] tram_addr_line;   // addr copy, so we can return to it at line start

    // state machine
    localparam IDLE     = 0;  // idle awaiting 'start'
    localparam INIT     = 1;  // initialize each frame
    localparam CHR_LINE = 2;  // at start of character line
    localparam SCR_LINE = 3;  // at start of screen line
    localparam AWAIT    = 4;  // wait to start drawing
    localparam DRAW     = 5;  // draw pixels

    localparam STATEW = 3;  // state width (bits)
    reg [STATEW-1:0] state, state_next;

    always @(*) begin
        case (state)
            IDLE:     state_next = start ? INIT : IDLE;
            INIT:     state_next = AWAIT;
            CHR_LINE: state_next = SCR_LINE;
            SCR_LINE: state_next = AWAIT;
            AWAIT:    state_next = (dx == -TEXT_LAT) ? DRAW : AWAIT;
            DRAW: begin
                if (dx == char_line_end) state_next = (dy == char_frame_end) ? IDLE : CHR_LINE;
                else state_next = DRAW;
            end
            default: state_next = IDLE;
        endcase
    end

    always @(posedge clk) begin
        state <= state_next;
        ucp <= tram_data[20:0];  // extract 21-bit Unicode code point

        case (state)
            INIT: begin
                tram_addr <= scroll_offs;
                tram_addr_line <= scroll_offs;
                line_id <= 0;
                tx <= 0;
                ty <= 0;
                gx <= 0;
                gy <= 0;
            end
            AWAIT: begin
                colr_fg <= tram_data[27:24];  // extract foreground colour
                colr_bg <= tram_data[31:28];  // extract background colour
                pix_line_reg <= pix_line;
            end
            DRAW: begin
                gx <= gx + 1;
                if (gx == 0) begin  // next buffer address
                    tram_addr <= (tram_addr == LAST_ADDR) ? 0 : tram_addr + 1;
                /* verilator lint_off WIDTH */
                end else if (gx == GLYPH_WIDTH-1) begin  // next char at end of glyph pixel line
                /* verilator lint_on WIDTH */
                    colr_fg <= tram_data[27:24];
                    colr_bg <= tram_data[31:28];
                    pix_line_reg <= pix_line;
                    tx <= tx + 1;
                end
            end
            CHR_LINE: begin  // new line of chars
                /* verilator lint_off WIDTH */
                if (gy == GLYPH_HEIGHT-1) begin  // first line of char glyph
                /* verilator lint_on WIDTH */
                    tram_addr_line <= tram_addr;  // copy address, so we can return to it
                    ty <= ty + 1;
                end
            end
            SCR_LINE: begin  // begin with first char on line
                tx <= 0;
                gx <= 0;
                gy <= gy + 1;
                line_id <= line_id + 1;
                tram_addr <= tram_addr_line;  // restore tram address
            end
        endcase

        if (rst) state <= IDLE;
    end

    reg paint_text_p2, paint_text_p1;
    always @(posedge clk) begin
        paint_text_p1 <= paint_text_p2;
        paint_text <= paint_text_p1;
        if (state == DRAW) begin
            pix <= pix_line_reg[gx] ? colr_fg : colr_bg;  // pixel colour index
            paint_text_p2 <= 1;
        end else begin
            pix <= 'h0;  // colour index 0 in non-paintable area
            paint_text_p2 <= 0;
        end
    end
endmodule
