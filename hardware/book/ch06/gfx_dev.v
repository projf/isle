// Isle.Computer - Device: Graphics
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module gfx_dev #(
    parameter BYTE_CNT=4,    // bytes in word
    parameter CORDW=16,      // signed coordinate width (bits)
    parameter DEV_ADDRW=10,  // device address width (bits)
    parameter WORD=32        // machine word size (bits)
    ) (
    input  wire clk_sys,  // system clock
    input  wire rst_sys,  // system reset
    input  wire [BYTE_CNT-1:0] we_sys,  // system write enable
    input  wire re_sys,  // system read enable
    input  wire [DEV_ADDRW-1:0] addr_sys,  // address
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [WORD-1:0] din_sys,  // data in
    /* verilator lint_on UNUSEDSIGNAL */
    output reg  [WORD-1:0] dout_sys,  // data out
    // external I/O signals
    input  wire signed [CORDW-1:0] disp_hres, disp_vres,  // display dims
    input  wire frame_start_sys, // frame start in system clock domain
    input  wire signed [CORDW-1:0] text_hres, text_vres,  // textmode dims
    input  wire signed [CORDW-1:0] tram_depth
    );

    // HW_REG_ADDR - must match software
    localparam [DEV_ADDRW-1:0] DISP_DIMS      = 'h100 >> 2;  // word addressing
    localparam [DEV_ADDRW-1:0] FRAME_FLAG     = 'h110 >> 2;
    localparam [DEV_ADDRW-1:0] FRAME_FLAG_CLR = 'h114 >> 2;
    localparam [DEV_ADDRW-1:0] TEXT_DIMS      = 'h200 >> 2;
    localparam [DEV_ADDRW-1:0] TRAM_DEPTH     = 'h204 >> 2;
    // END_HW_REG_ADDR

    // frame flag
    reg frame_flag, frame_flag_clr;

    // clear frame flag (strobe)
    always @(*) frame_flag_clr = (&we_sys && (addr_sys == FRAME_FLAG_CLR));

    // update frame flag
    always @(posedge clk_sys) begin
        if (frame_start_sys) frame_flag <= 1;
        else if (frame_flag_clr) frame_flag <= 0;
        if (rst_sys) frame_flag <= 0;
    end

    always @(posedge clk_sys) begin
        if (re_sys) begin
            case (addr_sys)
                DISP_DIMS:  dout_sys <= {disp_vres, disp_hres};
                FRAME_FLAG: dout_sys <= {{WORD-1{1'b0}}, frame_flag};
                TEXT_DIMS:  dout_sys <= {text_vres, text_hres};
                TRAM_DEPTH: dout_sys <= {{WORD-CORDW{1'b0}}, tram_depth};
                default: dout_sys <= 0;
            endcase
        end
        if (rst_sys) dout_sys <= 0;
    end
endmodule
