// Isle.Computer - XC7 Dual clock generation
// Copyright Isle Authors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module clock2_gen #(
    parameter MULT_MASTER=2.0,  // master clock multiplier (2.000-64.000)
    parameter DIV_MASTER=2,     // master clock divider (1-106)
    parameter DIV_5X=1.0,       // 5x clock divider
    parameter DIV_1X=1,         // 1x clock divider
    parameter IN_PERIOD=10.0    // period of master clock in ns (10 ns == 100 MHz)
    ) (
    input  wire clk_in,      // input clock
    output wire clk_5x_out,  // output 5x clock
    output wire clk_out,     // output clock
    output reg  clk_locked   // clock locked?
    );

    wire feedback;      // internal clock feedback
    wire clk_unbuf;     // unbuffered output clock
    wire clk_5x_unbuf;  // unbuffered 5x output clock
    wire locked;        // unsynced lock signal

    MMCME2_BASE #(
        .CLKFBOUT_MULT_F(MULT_MASTER),
        .CLKIN1_PERIOD(IN_PERIOD),
        .CLKOUT0_DIVIDE_F(DIV_5X),
        .CLKOUT1_DIVIDE(DIV_1X),
        .DIVCLK_DIVIDE(DIV_MASTER)
    ) MMCME2_BASE_inst (
        .CLKIN1(clk_in),
        .RST(1'b0),
        .CLKOUT0(clk_5x_unbuf),
        .CLKOUT1(clk_unbuf),
        .LOCKED(locked),
        .CLKFBOUT(feedback),
        .CLKFBIN(feedback),
        /* verilator lint_off PINCONNECTEMPTY */
        .CLKOUT0B(),
        .CLKOUT1B(),
        .CLKOUT2(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .CLKFBOUTB(),
        .PWRDWN()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // explicitly buffer output clocks
    BUFG bufg_clk(.I(clk_unbuf), .O(clk_out));
    BUFG bufg_clk_5x_out(.I(clk_5x_unbuf), .O(clk_5x_out));

    // ensure clock lock is synced with output clock
    reg locked_sync;
    always @(posedge clk_out) begin
        locked_sync <= locked;
        clk_locked <= locked_sync;
    end
endmodule
