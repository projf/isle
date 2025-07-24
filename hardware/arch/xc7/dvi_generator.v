// Isle.Computer - XC7 DVI Generator
// Copyright Isle Authors
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

    oserdes_10b serialize_ch0 (
        .clk(clk_pix),
        .clk_hs(clk_pix_5x),
        .rst(rst_pix),
        .data_in(tmds_ch0),
        .serial_out(ch0_dout)
    );

    oserdes_10b serialize_ch1 (
        .clk(clk_pix),
        .clk_hs(clk_pix_5x),
        .rst(rst_pix),
        .data_in(tmds_ch1),
        .serial_out(ch1_dout)
    );

    oserdes_10b serialize_ch2 (
        .clk(clk_pix),
        .clk_hs(clk_pix_5x),
        .rst(rst_pix),
        .data_in(tmds_ch2),
        .serial_out(ch2_dout)
    );

    oserdes_10b serialize_chc (
        .clk(clk_pix),
        .clk_hs(clk_pix_5x),
        .rst(rst_pix),
        .data_in(10'b0000011111),
        .serial_out(clk_dout)
    );
endmodule
