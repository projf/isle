// Isle.Computer - Display Timings
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// NB. pixel clock must match display mode

`default_nettype none
`timescale 1ns / 1ps

module display_timings #(
    parameter CORDW=16,  // signed coordinate width (bits)
    parameter MODE=0     // display mode (see display_modes.vh)
    ) (
    input  wire clk_pix,                 // pixel clock
    input  wire rst_pix,                 // reset in pixel clock domain
    output reg signed [CORDW-1:0] dx,    // horizontal display position
    output reg signed [CORDW-1:0] dy,    // vertical display position
    output reg hsync,                    // horizontal sync
    output reg vsync,                    // vertical sync
    output reg de,                       // data enable (low in blanking)
    output reg frame_start,              // high for one cycle at frame start
    output reg line_start                // high for one cycle at line start
    );

    `include "display_modes.vh"

    reg signed [CORDW-1:0] x, y;  // uncorrected display position (1 cycle early)

    `ifdef BENCH  // ensure frame_start and line_start xd works in simulation
    initial begin
        frame_start = 0;
        line_start = 0;
        x = 0;
        y = 0;
    end
    `endif

    // generate horizontal and vertical sync with correct polarity
    always @(posedge clk_pix) begin
        hsync <= H_POL ? (x >= HS_STA && x < HS_END) : ~(x >= HS_STA && x < HS_END);
        vsync <= V_POL ? (y >= VS_STA && y < VS_END) : ~(y >= VS_STA && y < VS_END);
        if (rst_pix) begin
            hsync <= H_POL ? 1'b0 : 1'b1;
            vsync <= V_POL ? 1'b0 : 1'b1;
        end
    end

    // control signals
    always @(posedge clk_pix) begin
        de          <= (y >= VA_STA && x >= HA_STA);
        frame_start <= (y == V_STA  && x == H_STA);
        line_start  <= (x == H_STA);
        if (rst_pix) begin
            de          <= 0;
            frame_start <= 1;  // after reset we immediately begin a frame...
            line_start  <= 1;  // ...and a line
        end
    end

    // calculate horizontal and vertical display position
    always @(posedge clk_pix) begin
        if (x == HA_END) begin  // last pixel on line?
            x <= H_STA;
            y <= (y == VA_END) ? V_STA : y + 1;  // last line on display?
        end else begin
            x <= x + 1;
        end
        if (rst_pix) begin
            x <= H_STA + 1;  // each coord only occurs once (1 cycle latency)
            y <= V_STA;
        end
    end

    // delay display position to match sync and control signals
    always @(posedge clk_pix) begin
        dx <= x;
        dy <= y;
        if (rst_pix) begin
            dx <= H_STA;
            dy <= V_STA;
        end
    end
endmodule
