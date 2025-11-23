// Isle.Computer - Font Glyph with Internal ROM
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module font_glyph #(
    parameter COUNT=128,     // number of characters in rom font
    parameter FILE_FONT="",  // font glyph ROM file
    parameter HEIGHT=16,     // glyph height (pixels)
    parameter LSB=0,         // first font pixel in LSB
    parameter UCPW=21,       // Unicode code point width (bits)
    parameter WIDTH=8        // glyph width (pixels)
    ) (
    input  wire clk,                           // clock
    input  wire rst,                           // reset
    input  wire [UCPW-1:0] ucp,                // Unicode code point
    input  wire [$clog2(HEIGHT)-1:0] line_id,  // glyph line to get
    output reg  [WIDTH-1:0] pix_line           // glyph pixel line
    );

    // map Unicode code point to glyph index in ROM
    reg [UCPW-1:0] glyph_idx;
    reg [$clog2(HEIGHT)-1:0] line_id_reg;
    always @(posedge clk) begin
        if (ucp >= 'h2580 && ucp <= 'h259F) glyph_idx <= ucp - 'h2580;  // block elements
        else if (ucp >= 'h20 && ucp <= 'h7E) glyph_idx <= ucp;  // basic Latin
        else if (ucp == 'hFFFD) glyph_idx <= 'h7F;  // replacement char
        else glyph_idx <= 'h11;  // light shade (for missing glyph AKA tofu)
        line_id_reg <= line_id;  // register line index to match glyph index calculation
    end

    // font glyph ROM
    localparam ADDRW = $clog2(HEIGHT * COUNT);
    reg [ADDRW-1:0] rom_addr;
    wire [WIDTH-1:0] rom_data;

    rom_sync #(
        .ADDRW(ADDRW),
        .DATAW(WIDTH),
        .FILE_INIT(FILE_FONT)
    ) glyph_rom (
        .clk(clk),
        .addr(rom_addr),
        .dout(rom_data)
    );

    integer i;  // for bit reversal
    always @(posedge clk) begin
        /* verilator lint_off WIDTH */
        rom_addr <= (glyph_idx * HEIGHT) + line_id_reg;
        /* verilator lint_on WIDTH */

        // reverse line if MSB is left-most pixel
        if (LSB) pix_line <= rom_data;
        else for (i=0; i<WIDTH; i=i+1) pix_line[i] <= rom_data[(WIDTH-1)-i];

        if (rst) begin
            rom_addr <= 0;
            pix_line <= 0;
        end
    end
endmodule
