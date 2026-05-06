// Isle.Computer - ECP5 DVI Generator
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module dvi_generator (
    input  wire clk_pix,         // pixel clock
    input  wire clk_pix_5x,      // 5x clock for 10:1 DDR SerDes
    input  wire rst_pix,         // reset in pixel clock domain
    input  wire de,              // data enable
    input  wire [7:0] ch0_din,   // channel 0 - data
    input  wire [7:0] ch1_din,   // channel 1 - data
    input  wire [7:0] ch2_din,   // channel 2 - data
    input  wire [1:0] ch0_ctrl,  // channel 0 - control
    input  wire [1:0] ch1_ctrl,  // channel 1 - control
    input  wire [1:0] ch2_ctrl,  // channel 2 - control
    output wire ch0_dout,        // channel 0 - serial TMDS
    output wire ch1_dout,        // channel 1 - serial TMDS
    output wire ch2_dout,        // channel 2 - serial TMDS
    output wire clk_dout         // clock channel - serial TMDS
    );

    wire [9:0] ch0_tmds, ch1_tmds, ch2_tmds;

    tmds_encoder ch0_encoder (
        .clk_pix(clk_pix),
        .rst_pix(rst_pix),
        .din(ch0_din),
        .ctrl_in(ch0_ctrl),
        .de(de),
        .tmds(ch0_tmds)
    );

    tmds_encoder ch1_encoder (
        .clk_pix(clk_pix),
        .rst_pix(rst_pix),
        .din(ch1_din),
        .ctrl_in(ch1_ctrl),
        .de(de),
        .tmds(ch1_tmds)
    );

    tmds_encoder ch2_encoder (
        .clk_pix(clk_pix),
        .rst_pix(rst_pix),
        .din(ch2_din),
        .ctrl_in(ch2_ctrl),
        .de(de),
        .tmds(ch2_tmds)
    );

    // use a separate ring counter for each channel to reduce fanout
    reg [4:0] ch0_ring5 = 5'b00001;
    reg [4:0] ch1_ring5 = 5'b00001;
    reg [4:0] ch2_ring5 = 5'b00001;
    always @(posedge clk_pix_5x) begin
        ch0_ring5 <= {ch0_ring5[3:0], ch0_ring5[4]};
        ch1_ring5 <= {ch1_ring5[3:0], ch1_ring5[4]};
        ch2_ring5 <= {ch2_ring5[3:0], ch2_ring5[4]};
    end

    // output 2 bits of TMDS data every cycle; load new TMDS data every 5 cycles
    reg [9:0] ch0_shift = 10'b0;
    reg [9:0] ch1_shift = 10'b0;
    reg [9:0] ch2_shift = 10'b0;
    always @(posedge clk_pix_5x) begin
        ch0_shift <= ch0_ring5[4] ? ch0_tmds : ch0_shift >> 2;  // shift two bits for DDR
        ch1_shift <= ch1_ring5[4] ? ch1_tmds : ch1_shift >> 2;
        ch2_shift <= ch2_ring5[4] ? ch2_tmds : ch2_shift >> 2;
    end

    // DDR output for three colour channels (and clock to avoid skew)
    ODDRX1F ch0_oddr (.D0(ch0_shift[0]), .D1(ch0_shift[1]), .Q(ch0_dout), .SCLK(clk_pix_5x), .RST(1'b0));
    ODDRX1F ch1_oddr (.D0(ch1_shift[0]), .D1(ch1_shift[1]), .Q(ch1_dout), .SCLK(clk_pix_5x), .RST(1'b0));
    ODDRX1F ch2_oddr (.D0(ch2_shift[0]), .D1(ch2_shift[1]), .Q(ch2_dout), .SCLK(clk_pix_5x), .RST(1'b0));
    ODDRX1F clk_oddr (.D0(1'b1),         .D1(1'b0),         .Q(clk_dout), .SCLK(clk_pix),    .RST(1'b0));
endmodule
