// Isle.Computer - Earthrise Command List
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module erlist #(
    parameter ADDRW=10,      // address width (bits)
    parameter BYTE=8,        // machine byte size (bits)
    parameter BYTE_CNT=4,    // bytes in machine word
    parameter FILE_INIT="",  // initial command list
    parameter WORD=32        // machine word size (bits)
    ) (
    input  wire clk,                    // clock
    input  wire [BYTE_CNT-1:0] we_sys,  // system write enable
    input  wire re_sys,                 // system read enable
    input  wire [ADDRW-1:0] addr_sys,   // system address
    input  wire [WORD-1:0] din_sys,     // system data in
    output reg  [WORD-1:0] dout_sys,    // system data out
    input  wire [ADDRW-1:0] addr_er,    // Earthrise address
    output reg  [WORD-1:0] dout_er      // Earthrise data out
    );

    localparam DEPTH=2**ADDRW;

    reg [WORD-1:0] erlist_mem [0:DEPTH-1];

    initial begin
        if (FILE_INIT != "") begin
            $display("Info: Load init file '%s' into Earthrise list.", FILE_INIT);
            $readmemh(FILE_INIT, erlist_mem);
        end
    end

    // system port (read-write)
    integer i;
    always @(posedge clk) begin
        if (re_sys) dout_sys <= erlist_mem[addr_sys];
        for (i=0; i<BYTE_CNT; i=i+1) begin
            if (we_sys[i]) erlist_mem[addr_sys][i*BYTE +: BYTE] <= din_sys[i*BYTE +: BYTE];
        end
    end

    // Earthrise port (read-only with additional output register)
    reg [WORD-1:0] dout_er_reg;
    always @(posedge clk) begin
        dout_er_reg <= erlist_mem[addr_er];
        dout_er <= dout_er_reg;
    end
endmodule
