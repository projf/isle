// Isle.Computer - Chapter 1: Display Square
// Copyright Isle Authors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module ch01_square #(
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

    // define a square with display coordinates
    reg square;
    always @(*) begin
        square = (dx > 220 && dx < 420) && (dy > 140 && dy < 340);
    end

    // paint colour: white inside square, blue outside
    reg [BPC-1:0] paint_r, paint_g, paint_b;
    always @(*) begin
        paint_r = (square) ? 'h1F : 'h02;
        paint_g = (square) ? 'h1F : 'h06;
        paint_b = (square) ? 'h1F : 'h0E;
    end


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
