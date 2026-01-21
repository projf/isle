// Isle.Computer - Synchronous ROM
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module rom_sync #(
    parameter ADDRW=7,     // address width (bits)
    parameter DATAW=8,     // data width (bits)
    parameter DEPTH=128,   // ROM depth
    parameter FILE_ROM=""  // set ROM contents
    ) (
    input  wire clk,               // clock
    input  wire [ADDRW-1:0] addr,  // address
    output reg  [DATAW-1:0] dout   // data out
    );

    reg [DATAW-1:0] rom_mem [0:DEPTH-1];

    initial begin
        if (FILE_ROM != "") begin
            $display("Create rom_sync with init file '%s'.", FILE_ROM);
            $readmemh(FILE_ROM, rom_mem);
        end else $display("Warning: Creating empty rom_sync because FILE_ROM isn't set.");
    end

    always @(posedge clk) dout <= rom_mem[addr];
endmodule
