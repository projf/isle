// Isle.Computer - Circle Drawing
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module circle #(parameter CORDW=0) (  // signed coordinate width
    input  wire clk,    // clock
    input  wire rst,    // reset
    input  wire start,  // start circle calculation
    input  wire oe,     // output enable
    input  wire signed [CORDW-1:0] r0,      // radius
    output reg  signed [CORDW-1:0] xa, ya,  // x and y distances
    output reg  busy,   // calculation in progress
    output reg  valid,  // output coordinates valid
    output reg  done    // calculation complete (high for one tick)
    );

    // internal variables
    reg signed [CORDW+1:0] err, err_tmp;  // error values (4x as wide as coords)

    // calc state machine
    localparam IDLE   = 0;
    localparam CALC_Y = 1;
    localparam CALC_X = 2;
    localparam VALID  = 3;
    localparam WAIT   = 4;

    localparam STATEW = 3;  // state width (bits)
    reg [STATEW-1:0] state;

    always @(posedge clk) begin
        case (state)
            CALC_Y: begin
                if (xa == 0) begin
                    state <= IDLE;
                    busy <= 0;
                    done <= 1;
                end else begin
                    state <= CALC_X;
                    err_tmp <= err;  // save existing error for next step
                    /* verilator lint_off WIDTH */
                    if (err <= ya) begin
                        ya <= ya + 1;
                        err <= err + 2 * (ya + 1) + 1;
                    end
                    /* verilator lint_on WIDTH */
                end
            end
            CALC_X: begin
                state <= VALID;
                /* verilator lint_off WIDTH */
                if (err_tmp > xa || err > ya) begin
                    xa <= xa + 1;
                    err <= err + 2 * (xa + 1) + 1;
                end
                /* verilator lint_on WIDTH */
            end
            VALID: if (oe) state <= WAIT;
            WAIT: state <= CALC_Y;  // wait one cycle after validity so we can latch values
            default: begin  // IDLE
                done <= 0;
                if (start) begin
                    state <= VALID;  // first coords from input
                    busy <= 1;
                    xa <= -r0;
                    ya <= 0;
                    err <= 2 - (2 * r0);
                end
            end
        endcase

        if (rst) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
        end
    end

    always @(*) valid = (state == VALID);
endmodule
