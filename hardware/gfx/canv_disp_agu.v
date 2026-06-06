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

    localparam PAINT_LAT = CLUT_LAT + 1;  // +1 for paint reg
    localparam ADDR_LAT = VRAM_LAT + CLUT_LAT + 2;  // +1 for in_window reg; +1 for AGU stage 2

    // separate y and x from canvas/window signals
    /* verilator lint_off UNUSEDSIGNAL */
    reg [CORDW-1:0] canv_h, canv_w;
    /* verilator lint_on UNUSEDSIGNAL */
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
    reg signed [CORDW-1:0] paint_x0, paint_x1;
    reg signed [CORDW-1:0] win_x0_lat, win_x1_lat;
    always @(posedge clk_pix) begin
        scale_x_minus <= (scale_x == 0) ? 0 : scale_x - 1;
        scale_y_minus <= (scale_y == 0) ? 0 : scale_y - 1;
        paint_x0 <= win_x0 - PAINT_LAT;
        paint_x1 <= win_x1 - PAINT_LAT;
        win_x0_lat <= win_x0 - ADDR_LAT;
        win_x1_lat <= win_x1 - ADDR_LAT;
    end

    // register latency corrected window and paint areas
    reg in_window;
    wire win_y = (dy >= win_y0) && (dy < win_y1);
    always @(posedge clk_pix) begin
        paint <= (dx >= paint_x0) && (dx < paint_x1) && win_y;  // output signal
        in_window <= (dx >= win_x0_lat) && (dx < win_x1_lat) && win_y;  // used in AGU stage 1
    end

    // pipelined signals
    reg [ADDRW-1:0] addr_base_p1;  // canvas base address
    reg [SHIFTW-1:0] addr_shift_p1;  // address shift bits

    // stage 1 - main calculation, handling frame and line starts
    reg [ADDRW+PIX_IDW-1:0] addr_pix, addr_pix_ln;  // pixel addresses
    reg [CORDW-1:0] cnt_x, cnt_y;  // scale counters
    always @(posedge clk_pix) begin
        if (rst_pix || frame_start) begin  // reset address and counters at start of frame
            cnt_y <= 0;
            cnt_x <= 0;
            addr_pix <= 0;
            addr_pix_ln <= 0;
        end else if (line_start && (dy > win_y0)) begin  // after 1st line in paint area
            cnt_x <= 0;  // reset x counter at line start
            if (cnt_y == scale_y_minus) begin
                cnt_y <= 0;
                addr_pix_ln <= addr_pix;  // save line address
            end else begin
                cnt_y <= cnt_y + 1;
                addr_pix <= addr_pix_ln;  // restore addr_pix_ln to repeat line
            end
        end else if (in_window) begin  // increment pixel address in window area
            if (cnt_x == scale_x_minus) begin
                addr_pix <= addr_pix + 1;
                cnt_x <= 0;
            end else cnt_x <= cnt_x + 1;
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
