// Isle.Computer - Canvas Display Address Generation Unit (AGU)
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// 2 cycle latency
// Assumes 2 cycle CLUT latency

`default_nettype none
`timescale 1ns / 1ps

module canv_disp_agu #(
    parameter CORDW=0,               // signed coordinate width (bits)
    parameter WORD=32,               // machine word size (bits)
    parameter ADDRW=0,               // vram address width (bits)
    parameter BMAP_LAT=0,            // latency for agu + vram + clut (cycles)
    parameter PIX_IDW=$clog2(WORD),  // pixel ID width (bits)
    parameter SHIFTW=0               // address shift width (bits)
    ) (
    input  wire clk_pix,                  // pixel clock
    input  wire rst_pix,                  // reset in pixel clock domain
    input  wire frame_start,              // frame start flag
    input  wire line_start,               // line start flag
    input  wire signed [CORDW-1:0] dx,    // horizontal display position
    input  wire signed [CORDW-1:0] dy,    // vertical display position
    input  wire [ADDRW-1:0] addr_base,    // canvas base address
    input  wire [SHIFTW-1:0] addr_shift,  // address shift bits
    input  wire [2*CORDW-1:0] win_start,  // canvas window start coords
    input  wire [2*CORDW-1:0] win_end,    // canvas window end coords
    input  wire [2*CORDW-1:0] scale,      // canvas scale
    output reg  [ADDRW-1:0] addr,         // pixel memory address
    output reg  [PIX_IDW-1:0] pix_id,     // pixel ID within word
    output reg  paint                     // canvas painting enable
    );

    localparam VRAM_OFFS = BMAP_LAT-1;  // first cycle handled by previous line

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

    // use window coords to determine paint area and vram read
    wire paint_y = (dy >= win_start_y) && (dy < win_end_y);
    wire paint_x = (dx >= win_start_x-2) && (dx < win_end_x-2);  // 2-stage pipeline
    wire vram_x  = (dx >= win_start_x-VRAM_OFFS) && (dx < win_end_x-VRAM_OFFS);

    // pipelined signals
    reg paint_p1;  // paint enable
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
            if (cnt_y == scale_y - 1) begin
                cnt_y <= 0;
                addr_pix_ln <= addr_pix;  // save line address
            end else begin
                cnt_y <= cnt_y + 1;
                addr_pix <= addr_pix_ln;  // restore addr_pix_ln to repeat line
            end
        end else if (paint_y && vram_x) begin  // increment address in vram read area
            if (cnt_x == scale_x - 1) begin
                addr_pix <= addr_pix + 1;
                cnt_x <= 0;
            end else cnt_x <= cnt_x + 1;
        end
        // pass to stage 2
        addr_base_p1 <= addr_base;
        addr_shift_p1 <= addr_shift;
        paint_p1 <= paint_y && paint_x;
    end

    // stage 2 - calculate memory address and pixel index
    wire [PIX_IDW-1:0] pix_id_mask = (1 << addr_shift) - 1;  // pixel index mask
    always @(posedge clk_pix) begin
        /* verilator lint_off WIDTHEXPAND */ /* verilator lint_off WIDTHTRUNC */
        addr <= addr_base_p1 + (addr_pix >> addr_shift_p1);
        /* verilator lint_on WIDTHTRUNC */ /* verilator lint_on WIDTHEXPAND */
        pix_id <= addr_pix[PIX_IDW-1:0] & pix_id_mask;
        paint <= paint_p1;
    end
endmodule
