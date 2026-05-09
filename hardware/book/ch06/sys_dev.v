// Isle.Computer - Device: System
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module sys_dev #(
    parameter DEV_ADDRW=10,     // device address width (bits)
    parameter TIMER_DIV=20000,  // milliseconds divider
    parameter WORD=32           // machine word size (bits)
    ) (
    input  wire clk,  // clock
    input  wire rst,  // reset
    input  wire we,   // write enable
    input  wire re,   // read enable
    input  wire [DEV_ADDRW-1:0] addr,  // address
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [WORD-1:0] din,  // data in
    /* verilator lint_on UNUSEDSIGNAL */
    output reg  [WORD-1:0] dout  // data out
    );

    // HW_REG_ADDR - must match software
    localparam [DEV_ADDRW-1:0] TIMER_0     = 'h300 >> 2;
    localparam [DEV_ADDRW-1:0] TIMER_0_CLR = 'h310 >> 2;
    localparam [DEV_ADDRW-1:0] LFSR_32     = 'h320 >> 2;
    // END_HW_REG_ADDR

    // timer reset signals (strobes)
    reg timer_0_clr;
    always @(*) timer_0_clr = (we && (addr == TIMER_0_CLR));

    // timer divider counters
    reg [$clog2(TIMER_DIV-1):0] cnt_timer_0;

    // timer
    reg [WORD-1:0] timer_0;

    // timer 0
    always @(posedge clk) begin
        if (timer_0_clr || rst) begin
            cnt_timer_0 <= 0;
            timer_0 <= 0;
        end else begin
            if (cnt_timer_0 == TIMER_DIV-1) begin
                cnt_timer_0 <= 0;
                timer_0 <= timer_0 + 1;
            end else cnt_timer_0 <= cnt_timer_0 + 1;
        end
    end

    // 32-bit LFSR (32,22,2,1)
    localparam TAPS = 32'b1000_0000_0010_0000_0000_0000_0000_0011;
    wire [WORD-1:0] lfsr_32;
    lfsr #(
        .LEN(WORD),
        .TAPS(TAPS)
    ) lsfr_inst (
        .clk(clk),
        .rst(rst),
        .en(1'b1),  // permanently enabled
        .seed(0),   // use default seed
        .sreg(lfsr_32)
    );

    // HW Reg MMIO
    always @(posedge clk) begin
        dout <= 0;  // no data out unless enabled

        if (re) begin
            case (addr)
                TIMER_0: dout <= timer_0;
                LFSR_32: dout <= lfsr_32;
                default: dout <= 0;
            endcase
        end
    end
endmodule
