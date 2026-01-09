// Isle.Computer - Clock Domain Crossing (CDC) for Flag
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module xd (
    input  wire clk_src,   // source domain clock
    input  wire clk_dst,   // destination domain clock
    input  wire flag_src,  // flag in source domain
    output wire flag_dst   // flag in destination domain
    );

    `ifdef BENCH  // play nicely in sim without reset
    initial begin
        toggle_src = 0;
        shr_dst = 0;
    end
    `endif

    // toggle reg when pulse received in source domain
    reg toggle_src;
    always @(posedge clk_src) toggle_src <= toggle_src ^ flag_src;

    // cross to destination domain via shift reg
    reg [3:0] shr_dst;
    always @(posedge clk_dst) shr_dst <= {shr_dst[2:0], toggle_src};

    // output pulse when transition occurs
    assign flag_dst = shr_dst[3] ^ shr_dst[2];
endmodule
