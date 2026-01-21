// Isle.Computer - Textmode RAM (TRAM)
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module tram #(
    parameter ADDRW=11,     // address width (bit)
    parameter BYTE=8,       // machine byte size (bits)
    parameter BYTE_CNT=4,   // bytes in machine word
    parameter FILE_TXT="",  // optional initial text to load
    parameter WORD=32       // machine word size (bits)
    ) (
    input  wire clk_sys,                // system clock
    input  wire clk_pix,                // pixel clock
    input  wire [BYTE_CNT-1:0] we_sys,  // system write enable
    input  wire re_sys,                 // system read enable
    input  wire [ADDRW-1:0] addr_sys,   // system address
    input  wire [WORD-1:0] din_sys,     // system data in
    output reg  [WORD-1:0] dout_sys,    // system data out
    input  wire [ADDRW-1:0] addr_disp,  // display address
    output reg  [WORD-1:0] dout_disp    // display data out
    );

    localparam DEPTH=2**ADDRW;

    reg [WORD-1:0] tram_mem [0:DEPTH-1];

    initial begin
        if (FILE_TXT != "") begin
            $display("Load text file '%s' into tram.", FILE_TXT);
            $readmemh(FILE_TXT, tram_mem);
        end
    end

    // system port (read-write)
    integer i;
    always @(posedge clk_sys) begin
        if (re_sys) dout_sys <= tram_mem[addr_sys];
        for (i=0; i<BYTE_CNT; i=i+1) begin
            if (we_sys[i]) tram_mem[addr_sys][i*BYTE +: BYTE] <= din_sys[i*BYTE +: BYTE];
        end
    end

    // display port (read-only)
    always @(posedge clk_pix) begin
        dout_disp <= tram_mem[addr_disp];
    end
endmodule
