// Isle.Computer - Synchronous FIFO
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module fifo_sync #(
    parameter ADDRW=4,  // address width (bits)
    parameter DATAW=8   // data width (bits)
    ) (
    input  wire clk,               // clock
    input  wire rst,               // reset
    input  wire we,                // write enable
    input  wire re,                // read enable
    input  wire [DATAW-1:0] din,   // data in
    output reg  [DATAW-1:0] dout,  // data out
    output wire [ADDRW-1:0] len,   // number of items in fifo (occupancy)
    output wire empty,             // fifo empty
    output wire full               // fifo full
    );

    localparam DEPTH = 2**ADDRW;  // usable capacity is one less
    reg [DATAW-1:0] fifo_mem [0:DEPTH-1];

    reg [ADDRW-1:0] wptr, rptr;  // write and read pointers

    // status
    assign empty = (rptr == wptr);
    assign full  = ((wptr + 1) == rptr);
    assign len   = wptr - rptr;

    // write
    always @(posedge clk) begin
        if (rst) wptr <= 0;
        else if (we && !full) begin
            fifo_mem[wptr] <= din;
            wptr <= wptr + 1;
        end
    end

    // read
    always @(posedge clk) begin
        if (rst) rptr <= 0;
        else if (re && !empty) begin
            dout <= fifo_mem[rptr];
            rptr <= rptr + 1;
        end
    end
endmodule
