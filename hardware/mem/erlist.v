// Isle.Computer - Earthrise Command List
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// RAM Type:     dual-port block ram
// Addressing:   word
// Write Enable: byte
// Write Mode:   no change (WRITEMODE=NORMAL for ECP5)

`default_nettype none
`timescale 1ns / 1ps

module erlist #(
    parameter BYTE=0,      // machine byte size (bits)
    parameter BYTE_CNT=0,   // bytes in machine word
    parameter WORD=0,       // machine word size (bits)
    parameter ADDRW=0,      // address width (bits)
    parameter FILE_INIT=""  // initial command list
    ) (
    input  wire clk,                    // clock
    input  wire [BYTE_CNT-1:0] we_sys,  // system write enable
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
        end else $display("Warning: Creating empty Earthrise list because FILE_INIT isn't set.");
    end

    // system port (read-write, write_mode: no change)
    integer i;
    always @(posedge clk) begin
        if (~|we_sys) dout_sys <= erlist_mem[addr_sys];
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
