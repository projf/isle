// Isle.Computer - Fast Line Drawing
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// Used for horizontal lines and fills

`default_nettype none
`timescale 1ns / 1ps

module fline #(parameter CORDW=16) (  // signed coordinate width
    input  wire clk,    // clock
    input  wire rst,    // reset
    input  wire start,  // start line calculation
    input  wire oe,     // output enable
    input  wire signed [CORDW-1:0] x0,  // point 0
    input  wire signed [CORDW-1:0] x1,  // point 1
    output reg  signed [CORDW-1:0] x,   // line position
    output wire busy,  // calculation in progress
    output wire valid  // output coordinates valid
    );

    // draw state machine
    localparam IDLE = 0;
    localparam DRAW = 1;

    localparam STATEW = 1;  // state width (bits)
    reg [STATEW-1:0] state;

    reg signed [CORDW-1:0] x_end;  // hold end coordinate

    always @(posedge clk) begin
        case (state)
            DRAW: begin
                if (oe) begin
                    if (x == x_end) state <= IDLE;
                    else x <= x + 1;
                end
            end
            default: begin  // IDLE
                if (start) begin
                    state <= DRAW;
                    x     <= (x1 >= x0) ? x0 : x1;
                    x_end <= (x1 >= x0) ? x1 : x0;
                end
            end
        endcase

        if (rst) state <= IDLE;
    end

    assign busy  = (state != IDLE) || start;
    assign valid = (state == DRAW && oe);
endmodule
