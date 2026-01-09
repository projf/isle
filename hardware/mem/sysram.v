// Isle.Computer - System RAM
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// RAM Type:     single-port block ram
// Addressing:   word
// Write Enable: byte
// Write Mode:   no change (WRITEMODE=NORMAL for ECP5)

`default_nettype none
`timescale 1ns / 1ps

module sysram #(
    parameter BYTE=0,       // machine byte size (bits)
    parameter BYTE_CNT=0,   // bytes in machine word
    parameter WORD=0,       // machine word size (bits)
    parameter ADDRW=0,      // address width (bits)
    parameter FILE_SOFT=""  // optional initial software to load
    ) (
    input  wire clk,                // clock
    input  wire [BYTE_CNT-1:0] we,  // write enable
    input  wire re,                 // read enable
    input  wire [ADDRW-1:0] addr,   // address
    input  wire [WORD-1:0] din,     // data in
    output reg  [WORD-1:0] dout     // data out
    );

    localparam DEPTH=2**ADDRW;

    reg [WORD-1:0] sysram_mem [0:DEPTH-1];

    initial begin
        if (FILE_SOFT != "") begin
            $display("Load software file '%s' into sysram.", FILE_SOFT);
            $readmemh(FILE_SOFT, sysram_mem);
        end
    end

    // system port (read-write, write_mode: no change)
    integer i;
    always @(posedge clk) begin
        if (re) dout <= sysram_mem[addr];
        for (i=0; i<BYTE_CNT; i=i+1) begin
            if (we[i]) sysram_mem[addr][i*BYTE +: BYTE] <= din[i*BYTE +: BYTE];
        end
    end
endmodule
