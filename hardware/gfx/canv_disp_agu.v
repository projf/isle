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
    input  wire clk_pix,                  // pixel clock
    input  wire rst_pix,                  // reset in pixel clock domain
    input  wire frame_start,              // frame start flag
    input  wire line_start,               // line start flag
    input  wire signed [CORDW-1:0] dx,    // horizontal display position
    input  wire signed [CORDW-1:0] dy,    // vertical display position
    input  wire [ADDRW-1:0] addr_base,    // canvas base address (word address)
    input  wire [SHIFTW-1:0] addr_shift,  // address shift bits
    input  wire [2*CORDW-1:0] win_start,  // canvas window start coords
    input  wire [2*CORDW-1:0] win_end,    // canvas window end coords
    input  wire [2*CORDW-1:0] scale,      // canvas scale
    output reg  [ADDRW-1:0] addr,         // pixel memory address
    output reg  [PIX_IDW-1:0] pix_id,     // pixel ID within word
    output reg  paint                     // canvas painting enable (pre-clut)
    );

    localparam PAINT_LAT = CLUT_LAT + 1;  // +1 for paint reg
    localparam ADDR_LAT = VRAM_LAT + CLUT_LAT + 2;  // +1 for vram_read reg; +1 for AGU stage 2

    // separate y and x from canvas window signals
    reg signed [CORDW-1:0] win_start_y, win_start_x;
    reg signed [CORDW-1:0] win_end_y, win_end_x;
    reg [CORDW-1:0] scale_y0, scale_x0;
    always @(*) begin
        {win_start_y, win_start_x} = win_start;
        {win_end_y, win_end_x} = win_end;
        {scale_y0, scale_x0} = scale;
    end

    // register signals to improve timing with hwreg
    reg [CORDW-1:0] scale_x_minus, scale_y_minus;
    reg signed [CORDW-1:0] paint_start_x, paint_end_x;
    reg signed [CORDW-1:0] vram_start_x, vram_end_x;
    always @(posedge clk_pix) begin
        scale_x_minus <= (scale_x0 == 0) ? 0 : scale_x0 - 1;
        scale_y_minus <= (scale_y0 == 0) ? 0 : scale_y0 - 1;
        paint_start_x <= win_start_x - PAINT_LAT;
        paint_end_x <= win_end_x - PAINT_LAT;
        vram_start_x <= win_start_x - ADDR_LAT;
        vram_end_x <= win_end_x - ADDR_LAT;
    end

    // register paint and vram read area as defined by window
    reg vram_read;
    wire win_y = (dy >= win_start_y) && (dy < win_end_y);
    always @(posedge clk_pix) begin
        paint <= (dx >= paint_start_x) && (dx < paint_end_x) && win_y;  // output signal
        vram_read <= (dx >= vram_start_x) && (dx < vram_end_x) && win_y;  // used in AGU stage 1
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
        end else if (line_start && (dy > win_start_y)) begin  // after 1st line in paint area
            cnt_x <= 0;  // reset x counter at line start
            if (cnt_y == scale_y_minus) begin
                cnt_y <= 0;
                addr_pix_ln <= addr_pix;  // save line address
            end else begin
                cnt_y <= cnt_y + 1;
                addr_pix <= addr_pix_ln;  // restore addr_pix_ln to repeat line
            end
        end else if (vram_read) begin  // increment pixel address in vram read area
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
    wire [PIX_IDW-1:0] pix_id_mask = (1 << addr_shift) - 1;  // pixel index mask
    always @(posedge clk_pix) begin
        /* verilator lint_off WIDTHEXPAND */ /* verilator lint_off WIDTHTRUNC */
        addr <= addr_base_p1 + (addr_pix >> addr_shift_p1);
        /* verilator lint_on WIDTHTRUNC */ /* verilator lint_on WIDTHEXPAND */
        pix_id <= addr_pix[PIX_IDW-1:0] & pix_id_mask;
    end
endmodule
