// Isle.Computer - Chapter 1: Hitomezashi Pattern
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module ch01_pattern #(
    parameter BPC=5,          // bits per colour channel
    parameter CORDW=16,       // signed coordinate width (bits)
    parameter DISPLAY_MODE=0  // display mode (see display.v for modes)
    ) (
    input  wire clk,                        // system clock
    input  wire rst,                        // reset
    output reg  signed [CORDW-1:0] disp_x,  // horizontal display position
    output reg  signed [CORDW-1:0] disp_y,  // vertical display position
    output reg  disp_hsync,                 // horizontal display sync
    output reg  disp_vsync,                 // vertical display sync
    output reg  disp_de,                    // display data enable
    output reg  disp_frame,                 // high for one cycle at frame start
    output reg  [BPC-1:0] disp_r,           // red display channel
    output reg  [BPC-1:0] disp_g,           // green display channel
    output reg  [BPC-1:0] disp_b            // blue display channel
    );

    //
    // Display Controller
    //

    wire signed [CORDW-1:0] dx, dy;
    wire hsync, vsync, de;
    wire frame_start;

    display #(
        .CORDW(CORDW),
        .MODE(DISPLAY_MODE)
    ) display_inst (
        .clk_pix(clk),
        .rst_pix(rst),
        /* verilator lint_off PINCONNECTEMPTY */
        .hres(),
        .vres(),
        /* verilator lint_on PINCONNECTEMPTY */
        .dx(dx),
        .dy(dy),
        .hsync(hsync),
        .vsync(vsync),
        .de(de),
        .frame_start(frame_start),
        /* verilator lint_off PINCONNECTEMPTY */
        .line_start()
        /* verilator lint_on PINCONNECTEMPTY */
    );


    //
    // Painting
    //

    // stitch start values: MSB first, so we can write left to right
    /* verilator lint_off ASCRANGE */
    reg [0:39] v_start;  // 40 vertical lines
    reg [0:29] h_start;  // 30 horizontal lines
    /* verilator lint_on ASCRANGE */

    initial begin  // random start values
        v_start = 40'b01100_00101_00110_10011_10101_10101_01111_01101;
        h_start = 30'b10111_01001_00001_10100_00111_01010;
    end

    // paint stitch pattern with 16x16 pixel grid
    reg stitch;
    reg v_line, v_on;
    reg h_line, h_on;
    reg last_h_stitch;
    always @(*) begin
        v_line = (dx[3:0] == 4'b0000);
        h_line = (dy[3:0] == 4'b0000);
        v_on = dy[4] ^ v_start[dx[9:4]];
        h_on = dx[4] ^ h_start[dy[8:4]];
        stitch = (v_line && v_on) || (h_line && h_on) || last_h_stitch;
    end

    always @(posedge clk) last_h_stitch <= h_line && h_on;

    // paint colour: yellow lines, blue background
    wire [BPC-1:0] paint_r = (stitch) ? 'h1F : 'h02;
    wire [BPC-1:0] paint_g = (stitch) ? 'h18 : 'h06;
    wire [BPC-1:0] paint_b = (stitch) ? 'h10 : 'h0E;


    //
    // Display Output
    //

    // register display signals
    always @(posedge clk) begin
        disp_x <= dx;
        disp_y <= dy;
        disp_hsync <= hsync;
        disp_vsync <= vsync;
        disp_de <= de;
        disp_frame <= frame_start;
        disp_r <= (de) ? paint_r : 'h00;  // paint colour but black in blanking
        disp_g <= (de) ? paint_g : 'h00;
        disp_b <= (de) ? paint_b : 'h00;
    end
endmodule
