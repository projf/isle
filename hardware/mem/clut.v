// Isle.Computer - Colour Lookup Table (CLUT)
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// RAM Type:     dual-port block ram
// Addressing:   word
// Write Enable: word
// Write Mode:   no change (WRITEMODE=NORMAL for ECP5)

`default_nettype none
`timescale 1ns / 1ps

module clut #(
    parameter ADDRW=0,     // address width (bits)
    parameter DATAW=0,     // data width (bits)
    parameter FILE_PAL=""  // initial palette file to load
    ) (
    input  wire clk_sys,                // system clock
    input  wire clk_pix,                // pixel clock
    input  wire we_sys,                 // system write enable
    input  wire re_sys,                 // system read enable
    input  wire [ADDRW-1:0] addr_sys,   // system address
    input  wire [DATAW-1:0] din_sys,    // system data in
    output reg  [DATAW-1:0] dout_sys,   // system data out
    input  wire [ADDRW-1:0] addr_disp,  // display address
    output reg  [DATAW-1:0] dout_disp   // display data out
    );

    localparam DEPTH=2**ADDRW;

    reg [DATAW-1:0] clut_mem [0:DEPTH-1];

    initial begin
        if (FILE_PAL != "") begin
            $display("Load palette file '%s' into clut.", FILE_PAL);
            $readmemh(FILE_PAL, clut_mem);
        end
    end

    // system port (read-write, write_mode: no change)
    always @(posedge clk_sys) begin
        if (re_sys) dout_sys <= clut_mem[addr_sys];
        if (we_sys) clut_mem[addr_sys] <= din_sys;
    end

    // display port (read-only with additional output register)
    reg [DATAW-1:0] dout_disp_reg;
    always @(posedge clk_pix) begin
        dout_disp_reg <= clut_mem[addr_disp];
        dout_disp <= dout_disp_reg;
    end
endmodule
