// Isle.Computer - XC7 DVI Generator
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

    oserdes_10b ch0_oserdes (
        .clk(clk_pix),
        .clk_hs(clk_pix_5x),
        .rst(rst_pix),
        .data_in(ch0_tmds),
        .serial_out(ch0_dout)
    );

    oserdes_10b ch1_oserdes (
        .clk(clk_pix),
        .clk_hs(clk_pix_5x),
        .rst(rst_pix),
        .data_in(ch1_tmds),
        .serial_out(ch1_dout)
    );

    oserdes_10b ch2_oserdes (
        .clk(clk_pix),
        .clk_hs(clk_pix_5x),
        .rst(rst_pix),
        .data_in(ch2_tmds),
        .serial_out(ch2_dout)
    );

    oserdes_10b clk_oserdes (
        .clk(clk_pix),
        .clk_hs(clk_pix_5x),
        .rst(rst_pix),
        .data_in(10'b0000011111),
        .serial_out(clk_dout)
    );
endmodule
