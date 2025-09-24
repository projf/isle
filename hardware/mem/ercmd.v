// Isle.Computer - Earthrise Command List
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// RAM Type:     sync dual-port block ram
// Addressing:   word
// Write Enable: byte
// Write Mode:   no change (WRITEMODE=NORMAL for ECP5)

`default_nettype none
`timescale 1ns / 1ps

module ercmd #(
    parameter BYTE_CNT=0,   // bytes in machine word
    parameter WORD=0,       // machine word size (bits)
    parameter ADDRW=0,      // address width (bits)
    parameter FILE_INIT=""  // initial command list
    ) (
    input  wire clk,                   // clock
    input  wire [BYTE_CNT-1:0] we,     // write enable
    input  wire [ADDRW-1:0] addr_sys,  // system address
    input  wire [WORD-1:0] din_sys,    // system data in
    output reg  [WORD-1:0] dout_sys,   // system data out
    input  wire [ADDRW-1:0] addr_er,   // Earthrise address
    output reg  [WORD-1:0] dout_er     // Earthrise data out
    );

    localparam DEPTH=2**ADDRW;
    reg [WORD-1:0] cmd_list_mem [0:DEPTH-1];

    initial begin
        if (FILE_INIT != 0) begin
            $display("Info: Load init file '%s' into Earthrise list.", FILE_INIT);
            $readmemh(FILE_INIT, cmd_list_mem);
        end else $display("Warning: Creating empty Earthrise list because FILE_INIT isn't set.");
    end

    // system port (read-write, write_mode: no change)
    always @(posedge clk) begin
        if (~|we) dout_sys <= cmd_list_mem[addr_sys];
        if (we[0]) cmd_list_mem[addr_sys][ 7: 0] <= din_sys[ 7: 0];
        if (we[1]) cmd_list_mem[addr_sys][15: 8] <= din_sys[15: 8];
        if (we[2]) cmd_list_mem[addr_sys][23:16] <= din_sys[23:16];
        if (we[3]) cmd_list_mem[addr_sys][31:24] <= din_sys[31:24];
    end

    // Earthrise port (read-only with output register)
    reg [WORD-1:0] dout_er_reg;
    always @(posedge clk) begin
        dout_er_reg <= cmd_list_mem[addr_er];
        dout_er <= dout_er_reg;
    end
endmodule
