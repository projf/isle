// Isle.Computer - Canvas Draw Address Generation Unit (AGU)
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// four-stage pipeline; ensure this matches Earthrise
// you should only trust the values of vram_addr and pix_idx when valid is high

`default_nettype none
`timescale 1ns / 1ps

module canv_draw_agu #(
    parameter ADDRW=14,               // address width (bits)
    parameter CORDW=16,               // signed coordinate width (bits)
    parameter SHIFTW=3,               // address shift width (bits)
    parameter WORD=32,                // machine word size (bits)
    localparam PIX_IDXW=$clog2(WORD)  // pixel index width (bits)
    ) (
    input  wire clk,                         // clock
    input  wire rst,                         // reset
    input  wire en,                          // enable
    input  wire [2*CORDW-1:0] canv_dims,     // canvas dimensions (not pipelined)
    input  wire [2*CORDW-1:0] pix_coord,     // pixel coordinate
    input  wire [ADDRW-1:0] vram_addr_base,  // base vram word address (not pipelined)
    input  wire [SHIFTW-1:0] addr_shift,     // address shift bits (not pipelined)
    input  wire wraph,                       // horizontal draw wrap
    input  wire wrapv,                       // vertical draw wrap
    output reg  [ADDRW-1:0] vram_addr,       // vram word address
    output reg  [PIX_IDXW-1:0] pix_idx,      // pixel index within word
    output reg  valid                        // high when vram address and pixel index are valid
    );

    localparam PIX_OFFSETW = ADDRW+$clog2(WORD);  // pixel offset width (bits)

    // separate y and x from canvas/pixels signals
    // dimensions are declared signed so comparisons with coordinates are signed
    reg signed [CORDW-1:0] canv_h, canv_w;  // canvas height and width
    reg signed [CORDW-1:0] pix_x, pix_y;  // pixel coordinates
    always @(*) begin
        {canv_h, canv_w} = canv_dims;
        {pix_y, pix_x} = pix_coord;
    end

    // pipeline registers
    reg signed [CORDW-1:0] pix_x_p1, pix_y_p1, pix_x_p2;
    reg valid_p2x, valid_p2y, valid_p3;
    reg [PIX_OFFSETW-1:0] pix_mul_p2, pix_offset_p3;

    always @(posedge clk) begin
        if (en) begin
            // stage 1
            if (wraph) begin
                if (pix_x < 0) pix_x_p1 <= pix_x + canv_w;
                else if (pix_x >= canv_w) pix_x_p1 <= pix_x - canv_w;
                else pix_x_p1 <= pix_x;
            end else pix_x_p1 <= pix_x;
            if (wrapv) begin
                if (pix_y < 0) pix_y_p1 <= pix_y + canv_h;
                else if (pix_y >= canv_h) pix_y_p1 <= pix_y - canv_h;
                else pix_y_p1 <= pix_y;
            end else pix_y_p1 <= pix_y;

            // stage 2
            pix_x_p2 <= pix_x_p1;  // use pix_x in the next stage
            // valid handles zero width and height
            valid_p2x <= (pix_x_p1 >= 0 && pix_x_p1 < canv_w);  // horizontal validity
            valid_p2y <= (pix_y_p1 >= 0 && pix_y_p1 < canv_h);  // vertical validity
            pix_mul_p2 <= canv_w * pix_y_p1;

            // stage 3
            valid_p3 <= valid_p2x && valid_p2y;
            pix_offset_p3 <= pix_mul_p2 + {{PIX_OFFSETW-CORDW{1'b0}}, pix_x_p2};

            // stage 4
            valid <= valid_p3;
            /* verilator lint_off WIDTHTRUNC */ /* verilator lint_off WIDTHEXPAND */
            vram_addr <= vram_addr_base + (pix_offset_p3 >> addr_shift);
            pix_idx <= pix_offset_p3 & ((1 << addr_shift) - 1);
            /* verilator lint_on WIDTHEXPAND */ /* verilator lint_on WIDTHTRUNC */
        end
        if (rst) begin  // reset valid so we don't use invalid addresses
            pix_x_p1 <= -1;  // ensure valid is correct in first cycle after reset
            pix_y_p1 <= -1;
            valid_p2x <= 0;
            valid_p2y <= 0;
            valid_p3 <= 0;
            valid <= 0;
        end
    end
endmodule
