// Isle.Computer - Canvas Draw Address Generation Unit (AGU)
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// four-stage pipeline; ensure this matches Earthrise
// you should only trust the values of vram_addr and pix_idx when clip is low

`default_nettype none
`timescale 1ns / 1ps

module canv_draw_agu #(
    parameter ADDRW=14,               // address width (bits)
    parameter CORDW=16,               // signed coordinate width (bits)
    parameter SHIFTW=3,               // address shift width (bits)
    parameter WORD=32,                // machine word size (bits)
    parameter PIX_IDXW=$clog2(WORD),  // pixel index width (bits)
    parameter PIX_OFFSETW=ADDRW+$clog2(WORD)  // pixel offset width (bits)
    ) (
    input  wire clk,                         // clock
    input  wire rst,                         // reset
    input  wire en,                          // enable
    input  wire [2*CORDW-1:0] canv_dims,     // canvas dimensions (not pipelined)
    input  wire [2*CORDW-1:0] pix_coord,     // pixel coordinate
    input  wire [ADDRW-1:0] vram_addr_base,  // base vram word address (not pipelined)
    input  wire [SHIFTW-1:0] addr_shift,     // address shift bits (not pipelined)
    input  wire draw_wrap,                   // wrap drawing addresses
    output reg  [ADDRW-1:0] vram_addr,       // vram word address
    output reg  [PIX_IDXW-1:0] pix_idx,      // pixel index within word
    output reg  clip                         // high for pixel coordinate outside canvas
    );

    // separate y and x from canvas/pixels signals
    reg [CORDW-1:0] canv_h, canv_w;  // canvas height and width
    reg signed [CORDW-1:0] pix_x, pix_y;  // pixel coordinates
    always @(*) begin
        {canv_h, canv_w} = canv_dims;
        {pix_y, pix_x} = pix_coord;
    end

    // pipeline registers
    reg signed [CORDW-1:0] pix_x_p1, pix_y_p1, pix_x_p2;
    reg clip_p2x, clip_p2y, clip_p3;
    reg [PIX_OFFSETW-1:0] pix_mul_p2, pix_offset_p3;

    always @(posedge clk) begin
        if (en) begin
            // stage 1
            if (draw_wrap) begin
                if (pix_x < 0) pix_x_p1 <= pix_x + canv_w;
                else if (pix_x >= canv_w) pix_x_p1 <= pix_x - canv_w;
                else pix_x_p1 <= pix_x;
                if (pix_y < 0) pix_y_p1 <= pix_y + canv_h;
                else if (pix_y >= canv_h) pix_y_p1 <= pix_y - canv_h;
                else pix_y_p1 <= pix_y;
            end else begin
                pix_x_p1 <= pix_x;
                pix_y_p1 <= pix_y;
            end

            // stage 2
            pix_x_p2 <= pix_x_p1;  // use pix_x in the next stage
            // clipping handles zero width and height
            clip_p2x <= (pix_x_p1 < 0 || pix_x_p1 >= canv_w);  // horizontal clip
            clip_p2y <= (pix_y_p1 < 0 || pix_y_p1 >= canv_h);  // vertical clip
            pix_mul_p2 <= canv_w * pix_y_p1;  // unsigned result

            // stage 3
            clip_p3 <= clip_p2x || clip_p2y;
            /* verilator lint_off WIDTHEXPAND */
            pix_offset_p3 <= pix_mul_p2 + pix_x_p2;
            /* verilator lint_on WIDTHEXPAND */

            // stage 4
            clip <= clip_p3;
            /* verilator lint_off WIDTHTRUNC */
            /* verilator lint_off WIDTHEXPAND */
            vram_addr <= vram_addr_base + (pix_offset_p3 >> addr_shift);
            pix_idx <= pix_offset_p3 & ((1 << addr_shift) - 1);
            /* verilator lint_on WIDTHEXPAND */
            /* verilator lint_on WIDTHTRUNC */
        end
        if (rst) begin  // reset clip so we don't use invalid addresses
            pix_x_p1 <= -1;  // ensure we remain clipped in first cycle after reset
            pix_y_p1 <= -1;
            clip_p2x <= 1'b1;
            clip_p2y <= 1'b1;
            clip_p3  <= 1'b1;
            clip     <= 1'b1;
        end
    end
endmodule
