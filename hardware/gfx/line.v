// Isle.Computer - Line Drawing
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module line #(parameter CORDW=16) (  // signed coordinate width
    input  wire clk,      // clock
    input  wire rst,      // reset
    input  wire start,    // start line calculation
    input  wire oe,       // output enable
    input  wire signed [CORDW-1:0] x0, y0,  // point 0
    input  wire signed [CORDW-1:0] x1, y1,  // point 1
    output reg  signed [CORDW-1:0] x,  y,   // line position
    output reg  signed [CORDW-1:0] lx,      // first x-coordinate for this y
    output reg  busy,   // calculation in progress
    output reg  valid,  // output coordinates valid
    output reg  fill,   // ready for fill
    output reg  done    // calculation complete (high for one tick)
    );

    // line properties
    reg swap;   // swap points to ensure y1 >= y0
    reg right;  // line direction
    reg signed [CORDW-1:0] xa, ya;  // start point
    reg signed [CORDW-1:0] xb, yb;  // end point
    reg signed [CORDW-1:0] x_end, y_end;  // register end point
    always @(*) begin
        swap = (y0 > y1);  // swap points if y0 is below y1
        xa = swap ? x1 : x0;
        xb = swap ? x0 : x1;
        ya = swap ? y1 : y0;
        yb = swap ? y0 : y1;
    end

    // error values
    reg signed [CORDW:0] err;  // a bit wider as signed
    reg signed [CORDW:0] dx, dy;
    reg movx, movy;  // horizontal/vertical move required
    always @(*) begin
        movx = (2*err >= dy);
        movy = (2*err <= dx);
    end

    // draw state machine
    localparam IDLE   = 0;
    localparam INIT_0 = 1;
    localparam INIT_1 = 2;
    localparam DRAW   = 3;

    localparam STATEW = 2;  // state width (bits)
    reg [STATEW-1:0] state;

    always @(*) valid  = (state == DRAW && oe);

    wire end_coord = (x == x_end && y == y_end);

    // when to fill a line
    always @(*) fill = (valid && (movy || end_coord));

    always @(posedge clk) begin
        case (state)
            DRAW: begin
                if (oe) begin
                    if (end_coord) begin
                        state <= IDLE;
                        busy <= 0;
                        done <= 1;
                    end else begin
                        if (movx && movy) begin
                            x <= right ? x + 1 : x - 1;
                            lx <= right ? x + 1 : x - 1;
                            y <= y + 1;
                            err <= err + dy + dx;
                        end else if (movx) begin
                            x <= right ? x + 1 : x - 1;
                            err <= err + dy;
                        end else if (movy) begin
                            y <= y + 1;
                            err <= err + dx;
                        end
                    end
                end
            end
            INIT_0: begin
                state <= INIT_1;
                dx <= right ? xb - xa : xa - xb;  // dx = abs(xb - xa)
                dy <= ya - yb;  // dy = -abs(yb - ya)
            end
            INIT_1: begin
                state <= DRAW;
                err <= dx + dy;
                x <= xa;
                y <= ya;
                lx <= xa;
                x_end <= xb;
                y_end <= yb;
            end
            default: begin  // IDLE
                done <= 0;
                if (start) begin
                    state <= INIT_0;
                    right <= (xa < xb);  // draw right to left?
                    busy <= 1;
                    x <= x0;  // init to start coords to avoid spurious pixels
                    y <= y0;
                    lx <= x0;
                end
            end
        endcase

        if (rst) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
        end
    end
endmodule
