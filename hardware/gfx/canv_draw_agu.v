// Isle.Computer - Canvas Draw Address Generation Unit (AGU)
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// pipelined draw address calculation (3 cycle latency)

`default_nettype none
`timescale 1ns / 1ps

module canv_draw_agu #(
    parameter CORDW=0,               // signed coordinate width (bits)
    parameter WORD=0,                // machine word size (bits)
    parameter ADDRW=0,               // address width (bits)
    parameter PIX_IDW=$clog2(WORD),  // pixel ID width (bits)
    parameter SHIFTW=0               // address shift width (bits)
    ) (
    input  wire clk,                      // clock
    input  wire signed [CORDW-1:0] w,     // canvas width
    input  wire signed [CORDW-1:0] h,     // canvas height
    input  wire signed [CORDW-1:0] x,     // horizontal pixel coordinate
    input  wire signed [CORDW-1:0] y,     // vertical pixel coordinate
    input  wire [ADDRW-1:0] addr_base,    // address of first pixel
    input  wire [SHIFTW-1:0] addr_shift,  // address shift bits
    output reg  [ADDRW-1:0] addr,         // pixel memory address
    output reg  [PIX_IDW-1:0] pix_id,     // pixel ID within word
    output reg  clip                      // high for coordinate outside canvas
    );

    localparam PIX_ADDRW = ADDRW + $clog2(WORD);

    // address and clip pipeline vars
    reg signed [CORDW-1:0] x_p1;
    reg clip_p1x, clip_p1y, clip_p2;
    reg [PIX_ADDRW-1:0] pix_mul_p1, pix_addr_p2;
    reg [SHIFTW-1:0] addr_shift_p1, addr_shift_p2;
    reg [ADDRW-1:0] addr_base_p1, addr_base_p2;

    always @(posedge clk) begin
        // stage 1
        x_p1 <= x;  // use x in the next stage
        clip_p1x <= (x < 0 || x > w-1);  // horizontal clip
        clip_p1y <= (y < 0 || y > h-1);  // vertical clip
        pix_mul_p1 <= w * y;  // unsigned result, but clip flags x<0 or y<0
        addr_shift_p1 <= addr_shift;
        addr_base_p1 <= addr_base;

        // stage 2
        clip_p2 <= clip_p1x || clip_p1y;
        /* verilator lint_off WIDTHEXPAND */
        pix_addr_p2 <= pix_mul_p1 + x_p1;
        /* verilator lint_on WIDTHEXPAND */
        addr_shift_p2 <= addr_shift_p1;
        addr_base_p2 <= addr_base_p1;

        // stage 3
        clip <= clip_p2;
        /* verilator lint_off WIDTHTRUNC */
        /* verilator lint_off WIDTHEXPAND */
        addr <= addr_base_p2 + (pix_addr_p2 >> addr_shift_p2);
        pix_id <= pix_addr_p2 & ((1 << addr_shift_p2) - 1);
        /* verilator lint_on WIDTHEXPAND */
        /* verilator lint_on WIDTHTRUNC */
    end
endmodule
