// Isle.Computer - Galois Linear-Feedback Shift Register
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// NB. Ensure reset is asserted for at least one cycle before enable

`default_nettype none
`timescale 1ns / 1ps

module lfsr #(
    parameter LEN=8,           // shift register length
    parameter TAPS='b10111000  // XOR taps
    ) (
    input  wire clk,             // clock
    input  wire rst,             // reset
    input  wire en,              // enable
    input  wire [LEN-1:0] seed,  // seed (uses default seed if zero)
    output reg  [LEN-1:0] sreg   // lfsr output
    );

    always @(posedge clk) begin
        if (rst) sreg <= (seed != 0) ? seed : {LEN{1'b1}};
        else if (en) sreg <= {1'b0, sreg[LEN-1:1]} ^ (sreg[0] ? TAPS : {LEN{1'b0}});
    end
endmodule
