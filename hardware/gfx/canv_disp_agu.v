// Isle.Computer - Canvas Display Address Generation Unit (AGU)
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// 2 cycle latency

`default_nettype none
`timescale 1ns / 1ps

module canv_disp_agu #(
    parameter ADDRW=14,             // vram address width (bits)
    parameter CLUT_LAT=2,           // clut display read latency (cycles; min=1)
    parameter CORDW=16,             // signed coordinate width (bits)
    parameter SHIFTW=3,             // address shift width (bits)
    parameter VRAM_LAT=2,           // vram display read latency (cycles; min=1)
    parameter WORD=32,              // machine word size (bits)
    parameter PIX_IDW=$clog2(WORD)  // pixel ID width (bits)
    ) (
    input  wire clk_pix,                   // pixel clock
    input  wire rst_pix,                   // reset in pixel clock domain
    input  wire frame_start,               // frame start flag
    input  wire line_start,                // line start flag
    input  wire signed [CORDW-1:0] dx,     // horizontal display position
    input  wire signed [CORDW-1:0] dy,     // vertical display position
    input  wire [ADDRW-1:0] addr_base,     // canvas base address (word address)
    input  wire [SHIFTW-1:0] addr_shift,   // address shift bits
    input  wire [2*CORDW-1:0] canv_dims,   // canvas dimensions
    input  wire [2*CORDW-1:0] canv_scale,  // canvas scale
    input  wire [2*CORDW-1:0] win_start,   // canvas window start coords
    input  wire [2*CORDW-1:0] win_end,     // canvas window end coords
    output reg  [ADDRW-1:0] addr,          // pixel memory address
    output reg  [PIX_IDW-1:0] pix_id,      // pixel ID within word
    output reg  paint                      // canvas painting enable (pre-clut)
    );

    localparam ADDR_LAT = VRAM_LAT + CLUT_LAT + 2;  // +1 for in_window reg; +1 for AGU stage 2
    localparam PAINT_OFFS = VRAM_LAT;  // paint latency offset from ADDR_LAT

    // separate y and x from canvas/window signals
    reg [CORDW-1:0] canv_h, canv_w;
    reg [CORDW-1:0] scale_y, scale_x;
    reg signed [CORDW-1:0] win_y0, win_x0;
    reg signed [CORDW-1:0] win_y1, win_x1;
    always @(*) begin
        {canv_h, canv_w} = canv_dims;
        {scale_y, scale_x} = canv_scale;
        {win_y0, win_x0} = win_start;
        {win_y1, win_x1} = win_end;
    end

    // register signals to improve timing with hwreg
    reg [CORDW-1:0] scale_x_minus, scale_y_minus;
    reg signed [CORDW-1:0] win_x0_lat, win_x1_lat;
    always @(posedge clk_pix) begin
        scale_x_minus <= (scale_x == 0) ? 0 : scale_x - 1;
        scale_y_minus <= (scale_y == 0) ? 0 : scale_y - 1;
        win_x0_lat <= win_x0 - ADDR_LAT;
        win_x1_lat <= win_x1 - ADDR_LAT;
    end

    // canvas paint area is intersection of window and canvas dims
    reg in_window;
    reg [CORDW-1:0] cnt_cx, cnt_cy;  // canvas counters
    wire in_canv_h = (cnt_cy < canv_h);
    wire in_canv_w = (cnt_cx < canv_w);
    wire canv_paint = in_canv_h & in_canv_w && in_window;

    // register latency corrected window and paint areas
    wire win_y = (dy >= win_y0) && (dy < win_y1);
    reg [PAINT_OFFS-1:0] paint_sr;
    always @(posedge clk_pix) begin
        in_window <= (dx >= win_x0_lat) && (dx < win_x1_lat) && win_y;  // used in AGU stage 1
        {paint, paint_sr} <= {paint_sr, canv_paint};
    end

    // pipelined signals
    reg [ADDRW-1:0] addr_base_p1;  // canvas base address
    reg [SHIFTW-1:0] addr_shift_p1;  // address shift bits

    // stage 1 - main calculation, handling frame and line starts
    reg [ADDRW+PIX_IDW-1:0] addr_pix, addr_pix_ln;  // pixel addresses
    reg [CORDW-1:0] cnt_sx, cnt_sy;  // window scale counters
    always @(posedge clk_pix) begin
        if (rst_pix || frame_start) begin  // reset address and counters at start of frame
            cnt_sx <= 0;
            cnt_sy <= 0;
            cnt_cx <= 0;
            cnt_cy <= 0;
            addr_pix <= 0;
            addr_pix_ln <= 0;
        end else if (line_start && (dy > win_y0)) begin  // after 1st line in paint area
            cnt_sx <= 0;  // reset x scale counter at line start
            cnt_cx <= 0;  // reset x canvas pixel counter at line start
            if (cnt_sy == scale_y_minus) begin
                cnt_sy <= 0;
                cnt_cy <= cnt_cy + 1;  // next canvas row
                addr_pix_ln <= addr_pix;  // save line address
            end else begin
                cnt_sy <= cnt_sy + 1;
                addr_pix <= addr_pix_ln;  // restore addr_pix_ln to repeat line
            end
        end else if (canv_paint) begin  // increment pixel address in window area
            if (cnt_sx == scale_x_minus) begin
                cnt_sx <= 0;
                cnt_cx <= cnt_cx + 1;  // next canvas pixel
                addr_pix <= addr_pix + 1;
            end else cnt_sx <= cnt_sx + 1;
        end
        // pass to stage 2
        addr_base_p1 <= addr_base;
        addr_shift_p1 <= addr_shift;
    end

    // stage 2 - calculate memory address and pixel index
    wire [PIX_IDW-1:0] pix_id_mask = (1 << addr_shift_p1) - 1;  // pixel index mask
    always @(posedge clk_pix) begin
        /* verilator lint_off WIDTHEXPAND */ /* verilator lint_off WIDTHTRUNC */
        addr <= addr_base_p1 + (addr_pix >> addr_shift_p1);
        /* verilator lint_on WIDTHTRUNC */ /* verilator lint_on WIDTHEXPAND */
        pix_id <= addr_pix[PIX_IDW-1:0] & pix_id_mask;
    end
endmodule
