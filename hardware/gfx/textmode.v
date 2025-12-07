// Isle.Computer - Textmode with Internal Glyph ROM
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// Assumes 1 cycle tram latency (no additional tram output register)

`default_nettype none
`timescale 1ns / 1ps

module textmode #(
    parameter CORDW=0,       // signed coordinate width (bits)
    parameter WORD=0,        // machine word size (bits)
    parameter ADDRW=0,       // tram address width (bits)
    parameter CIDXW=0,       // colour index width (bits)
    // parameter CLUT_LAT=0,    // CLUT latency (cycles)
    parameter FILE_FONT="",  // font glyph ROM file
    parameter FONT_COUNT=0,  // number of glyphs in font ROM
    parameter TRAM_HRES=0,   // tram width (chars)
    parameter TRAM_VRES=0    // tram height (chars)
    ) (
    input  wire clk_pix,                       // pixel clock
    input  wire rst_pix,                       // reset in pixel clock domain
    input  wire frame_start,                   // frame start flag
    input  wire [ADDRW-1:0] scroll_offs,       // tram scroll offset
    input  wire signed [CORDW-1:0] dx, dy,     // display position
    input  wire signed [ADDRW-1:0] text_hres,  // text display width (chars)
    input  wire signed [ADDRW-1:0] text_vres,  // text display height (chars)
    input  wire [2*CORDW-1:0] win_start,       // text window start coords
    input  wire [2*CORDW-1:0] win_end,         // text window end coords
    input  wire [2*CORDW-1:0] scale,           // text mode scale
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [WORD-1:0] tram_data,          // char data - [23:21] unused
    /* verilator lint_on UNUSEDSIGNAL */
    output reg  [ADDRW-1:0] tram_addr,         // tram address
    output reg  [CIDXW-1:0] pix,               // pixel colour index
    output reg  paint                          // textmode painting enable
    );

    localparam GLYPH_HEIGHT   = 16;  // glyph height (pixels) - must be pow of 2
    localparam GLYPH_WIDTH    =  8;  // singe-width glyph width (pixels)
    localparam UCPW           = 21;  // Unicode code point width (bits)
    localparam LAST_ADDR = TRAM_HRES * TRAM_VRES - 1;  // end of tram

    localparam FONT_LAT = 4;  // font glyph latency
    // localparam TRAM_LAT = 2;  // including address set
    // localparam TOT_LAT = TRAM_LAT + FONT_LAT + CLUT_LAT;

    // separate y and x from canvas window signals
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

    // flags
    reg signed [CORDW-1:0] char_line_end;
    reg signed [CORDW-1:0] char_frame_end;

    always @(posedge clk_pix) begin
        char_line_end  <= (GLYPH_WIDTH  * text_hres * scale_x) - 1;
        char_frame_end <= (GLYPH_HEIGHT * text_vres * scale_y) - 1;
    end

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

    reg [GLYPH_HEIGHT_W-1:0] line_id;  // which ROM line to fetch
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
    reg [STATEW-1:0] state, state_next;

    always @(*) begin
        case (state)
            IDLE: state_next = frame_start ? INIT : IDLE;
            INIT: state_next = (dy == win_start_y) ? AWAIT : INIT;
            AWAIT: state_next = (dx == win_start_x-FONT_LAT) ? DRAW : AWAIT;
            DRAW: begin
                if (dx == char_line_end || dx >= win_end_x-1)
                    state_next = (dy == char_frame_end || dy >= win_end_y-1) ? IDLE : CHR_LINE;
                else state_next = DRAW;
            end
            CHR_LINE: state_next = SCR_LINE;
            SCR_LINE: state_next = AWAIT;
            default: state_next = IDLE;
        endcase
    end

    always @(posedge clk_pix) begin
        state <= state_next;

        case (state)
            INIT: begin
                tram_addr <= scroll_offs;
                tram_addr_line <= scroll_offs;
                line_id <= 0;
                tx <= 0;
                ty <= 0;
                gx <= 0;
                gy <= 0;
                cnt_x <= 0;
                cnt_y <= 0;
            end
            AWAIT: begin  // get colours and pixels for first glyph on line
                colr_fg <= tram_data[WORD-CIDXW-1:WORD-2*CIDXW];
                colr_bg <= tram_data[WORD-1:WORD-CIDXW];
                pix_line_reg <= pix_line;
                ucp <= tram_data[UCPW-1:0];  // Unicode code point from tram
            end
            DRAW: begin
                // step through horizontal pixels
                if (cnt_x == scale_x-1) begin
                    cnt_x <= 0;
                    gx <= gx + 1;
                end else cnt_x <= cnt_x + 1;

                // advance tram address once we've started rendering a glyph
                if (gx == 0 && cnt_x == 0) begin
                    tram_addr <= (tram_addr == LAST_ADDR) ? scroll_offs : tram_addr + 1;  // next address or wrap around
                end else if (gx == 2 && cnt_x == 0) begin  // wait 2 cycles for address and tram data out - MAGIC NUMBER
                    ucp <= tram_data[UCPW-1:0];  // Unicode code point from tram
                /* verilator lint_off WIDTH */
                end else if (gx == GLYPH_WIDTH-1 && cnt_x == scale_x-1) begin  // load next glyph at end of current glyph
                /* verilator lint_on WIDTH */
                    colr_fg <= tram_data[WORD-CIDXW-1:WORD-2*CIDXW];
                    colr_bg <= tram_data[WORD-1:WORD-CIDXW];
                    pix_line_reg <= pix_line;
                    tx <= tx + 1;
                end
            end
            CHR_LINE: begin  // prepare for next line of chars if required
                /* verilator lint_off WIDTH */
                if (gy == GLYPH_HEIGHT-1 && cnt_y == scale_y-1) begin  // last line of char glyph
                /* verilator lint_on WIDTH */
                    tram_addr <= tram_addr_line + text_hres;
                    tram_addr_line <= tram_addr_line + text_hres;  // copy to restore later
                    ty <= ty + 1;  // move down to next line of chars
                end
            end
            SCR_LINE: begin  // new line of pixels; begin with first char on line
                tx <= 0;
                gx <= 0;
                cnt_x <= 0;
                tram_addr <= tram_addr_line;  // restore tram address

                // step through vertical pixels
                if (cnt_y == scale_y-1) begin
                    cnt_y <= 0;
                    gy <= gy + 1;
                    line_id <= line_id + 1;
                end else cnt_y <= cnt_y + 1;
            end
        endcase

        if (rst_pix) state <= IDLE;
    end

    // output text pixels - display controlled by paint signal
    always @(posedge clk_pix) pix <= pix_line_reg[gx] ? colr_fg : colr_bg;

    font_glyph #(
        .FONT_COUNT(FONT_COUNT),
        .FILE_FONT(FILE_FONT)
    ) font_glyph_instance (
        .clk(clk_pix),
        .rst(rst_pix),
        .ucp(ucp),
        .line_id(line_id),
        .pix_line(pix_line)
    );
endmodule
