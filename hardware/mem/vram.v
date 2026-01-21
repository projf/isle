// Isle.Computer - Video RAM (VRAM)
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module vram #(
    parameter ADDRW=14,      // address width ≥14 (bits)
    parameter FILE_BMAP="",  // optional initial bitmap to load
    parameter WORD=32        // machine word size (bits)
    ) (
    input  wire clk_sys,                // system clock
    input  wire clk_pix,                // pixel clock
    input  wire [WORD-1:0] wmask_sys,   // system write mask
    input  wire re_sys,                 // system read enable
    input  wire [ADDRW-1:0] addr_sys,   // system word address
    input  wire [WORD-1:0] din_sys,     // system data in
    output reg  [WORD-1:0] dout_sys,    // system data out
    input  wire [ADDRW-1:0] addr_disp,  // display word address
    output reg  [WORD-1:0] dout_disp    // display data out
    );

    localparam DEPTH=2**ADDRW;

    reg [WORD-1:0] vram_mem [0:DEPTH-1];

    initial begin
        if (FILE_BMAP != "") begin
            $display("Load bitmap file '%s' into vram.", FILE_BMAP);
            $readmemh(FILE_BMAP, vram_mem);
        end
    end

    // system port (read-write)
    integer i;
    always @(posedge clk_sys) begin
        if (re_sys) dout_sys <= vram_mem[addr_sys];
        for (i=0; i<WORD; i=i+1) begin
            if (wmask_sys[i]) vram_mem[addr_sys][i] <= din_sys[i];
        end
    end

    // display port (read-only with additional output register)
    reg [WORD-1:0] dout_disp_reg;
    always @(posedge clk_pix) begin
        dout_disp_reg <= vram_mem[addr_disp];
        dout_disp <= dout_disp_reg;
    end
endmodule
