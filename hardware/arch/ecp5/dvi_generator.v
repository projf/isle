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

    wire [9:0] tmds_ch0, tmds_ch1, tmds_ch2;

    tmds_encoder encode_ch0 (
        .clk_pix(clk_pix),
        .rst_pix(rst_pix),
        .din(ch0_din),
        .ctrl_in(ch0_ctrl),
        .de(de),
        .tmds(tmds_ch0)
    );

    tmds_encoder encode_ch1 (
        .clk_pix(clk_pix),
        .rst_pix(rst_pix),
        .din(ch1_din),
        .ctrl_in(ch1_ctrl),
        .de(de),
        .tmds(tmds_ch1)
    );

    tmds_encoder encode_ch2 (
        .clk_pix(clk_pix),
        .rst_pix(rst_pix),
        .din(ch2_din),
        .ctrl_in(ch2_ctrl),
        .de(de),
        .tmds(tmds_ch2)
    );

    // use a separate ring counter for each channel to reduce fanout
    reg [4:0] shift5_ch0 = 5'b00001;
    reg [4:0] shift5_ch1 = 5'b00001;
    reg [4:0] shift5_ch2 = 5'b00001;

    reg [9:0] ch0_shift, ch1_shift, ch2_shift;

    // shift 2 bits of TMDS data every cycle; load new TMDS data every 5 cycles
    always @(posedge clk_pix_5x) begin
        shift5_ch0 <= {shift5_ch0[3:0], shift5_ch0[4]};
        shift5_ch1 <= {shift5_ch1[3:0], shift5_ch1[4]};
        shift5_ch2 <= {shift5_ch2[3:0], shift5_ch2[4]};
        ch0_shift <= shift5_ch0[4] ? tmds_ch0 : ch0_shift >> 2;  // shift two bits for DDR
        ch1_shift <= shift5_ch1[4] ? tmds_ch1 : ch1_shift >> 2;
        ch2_shift <= shift5_ch2[4] ? tmds_ch2 : ch2_shift >> 2;
    end

    ODDRX1F serialize_ch0 (.D0(ch0_shift[0]), .D1(ch0_shift[1]), .Q(ch0_dout), .SCLK(clk_pix_5x), .RST(1'b0));
    ODDRX1F serialize_ch1 (.D0(ch1_shift[0]), .D1(ch1_shift[1]), .Q(ch1_dout), .SCLK(clk_pix_5x), .RST(1'b0));
    ODDRX1F serialize_ch2 (.D0(ch2_shift[0]), .D1(ch2_shift[1]), .Q(ch2_dout), .SCLK(clk_pix_5x), .RST(1'b0));
    ODDRX1F serialize_clk (.D0(1'b1),         .D1(1'b0),         .Q(clk_dout), .SCLK(clk_pix),    .RST(1'b0));
endmodule
