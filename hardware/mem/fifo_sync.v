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
    output reg  dout_valid,        // high when dout is valid
    output wire [ADDRW-1:0] len,   // length; number of items (occupancy)
    output wire empty,             // fifo empty
    output wire full               // fifo full
    );

    localparam DEPTH = 2**ADDRW;  // usable capacity is one less
    reg [DATAW-1:0] fifo_mem [0:DEPTH-1];

    reg [ADDRW-1:0] wptr, rptr;  // write and read pointers
    wire [ADDRW-1:0] wptr_next = wptr + 1'b1;  // ensure full works when memory wraps
    wire [ADDRW-1:0] rptr_next = rptr + 1'b1;

    // status
    assign empty = (rptr == wptr);
    assign full  = (wptr_next == rptr);
    assign len   = wptr - rptr;

    // write
    always @(posedge clk) begin
        if (rst) wptr <= 0;
        else if (we && !full) begin
            fifo_mem[wptr] <= din;
            wptr <= wptr_next;
        end
    end

    // read
    always @(posedge clk) begin
        if (rst) rptr <= 0;
        else if (re && !empty) begin
            dout <= fifo_mem[rptr];
            rptr <= rptr_next;
        end
        dout_valid <= re && !empty;
    end
endmodule
