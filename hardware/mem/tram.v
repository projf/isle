// Isle.Computer - Textmode RAM (TRAM)
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// RAM Type:     async dual-port block ram
// Addressing:   word
// Write Enable: byte
// Write Mode:   no change (WRITEMODE=NORMAL for ECP5)

`default_nettype none
`timescale 1ns / 1ps

module tram #(
    parameter BYTE_CNT=0,  // bytes in machine word
    parameter WORD=0,      // machine word size (bits)
    parameter ADDRW=0,     // address width (bit)
    parameter FILE_TXT=""  // optional initial text to load
    ) (
    input  wire clk_sys,                // system clock
    input  wire clk_pix,                // pixel clock
    input  wire [BYTE_CNT-1:0] we_sys,  // system write enable
    input  wire [ADDRW-1:0] addr_sys,   // system address
    input  wire [ADDRW-1:0] addr_disp,  // display address
    input  wire [WORD-1:0] din_sys,     // system data in
    output reg  [WORD-1:0] dout_sys,    // system data out
    output reg  [WORD-1:0] dout_disp    // display data out
    );

    localparam DEPTH=2**ADDRW;
    (* no_rw_check *)
    reg [WORD-1:0] tram_mem [0:DEPTH-1];

    initial begin
        if (FILE_TXT != 0) begin
            $display("Load text file '%s' into tram.", FILE_TXT);
            $readmemh(FILE_TXT, tram_mem);
        end
    end

    // system port (read-write, write_mode: no change)
    always @(posedge clk_sys) begin
        if (~|we_sys) dout_sys <= tram_mem[addr_sys];
        if (we_sys[0]) tram_mem[addr_sys][ 7: 0] <= din_sys[ 7: 0];
        if (we_sys[1]) tram_mem[addr_sys][15: 8] <= din_sys[15: 8];
        if (we_sys[2]) tram_mem[addr_sys][23:16] <= din_sys[23:16];
        if (we_sys[3]) tram_mem[addr_sys][31:24] <= din_sys[31:24];
    end

    // display port (read-only, no output register)
    always @(posedge clk_pix) dout_disp <= tram_mem[addr_disp];
endmodule
