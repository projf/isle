// Isle.Computer - xN1 UART Receiver
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

// default params configured for 115200 baud with 20 MHz system clock

module uart_rx #(
    parameter UART_CNT_INC=6036,  // 16 x baud counter increment
    parameter UART_CNT_W=16,      // 16 x baud counter width (bits)
    parameter UART_DATAW=8        // UART data width (bits)
    ) (
    input  wire clk,        // clock
    input  wire rst,        // reset
    input  wire serial_in,  // serial data in
    output reg  [UART_DATAW-1:0] dout,  // data received
    output reg  rx_busy,    // busy receiving
    output reg  rx_done     // receive complete
    );

    // 16 x baud strobe generator
    reg stb_16xbaud;
    reg [UART_CNT_W-1:0] cnt_16xbaud;
    always @(posedge clk) begin
        {stb_16xbaud, cnt_16xbaud} <= cnt_16xbaud + UART_CNT_INC;

        if (rst) begin
            stb_16xbaud <= 0;
            cnt_16xbaud <= 0;
        end
    end

    // sampling params (only one sample in this implementation)
    localparam SAMPLES   = 16;  // samples per baud (must be power of 2)
    localparam SAMPLES_W = $clog2(SAMPLES);
    /* verilator lint_off WIDTHTRUNC */
    localparam [SAMPLES_W-1:0] SAMPLE_A    = SAMPLES/2 - 1;  // middle bit
    localparam [SAMPLES_W-1:0] SAMPLE_LAST = SAMPLES - 1;    // last sample
    /* verilator lint_on WIDTHTRUNC */

    // sync serial serial_in to combat metastability
    reg rx_0, rx;
    always @(posedge clk) begin
        rx_0 <= serial_in;
        rx <= rx_0;
        if (rst) begin  // default high as start is triggered by rx going low
            rx_0 <= 1;
            rx <= 1;
        end
    end

    // state machine
    localparam IDLE  = 0;
    localparam START = 1;
    localparam DATA  = 2;
    localparam STOP  = 3;
    localparam STATEW = 2;  // state width (bits) - must cover largest state machine param
    reg [STATEW-1:0] state, state_next;

    // data index
    localparam IDX_W = $clog2(UART_DATAW);
    reg [IDX_W-1:0] data_idx, data_idx_next;
    /* verilator lint_off WIDTHTRUNC */
    localparam [IDX_W-1:0] LAST_BIT = UART_DATAW - 1;
    /* verilator lint_on WIDTHTRUNC */

    // sample counter and data
    reg [SAMPLES_W-1:0] s_cnt, s_cnt_next;
    reg sample_a, sample_a_next;    // sample data
    reg [UART_DATAW-1:0] data_tmp;  // hold data output as we receive it
    reg bit_done, bit_done_next;    // bit ready to save
    reg rx_done_next;               // receive done next

    always @(posedge clk) begin
        state <= state_next;
        data_idx <= data_idx_next;
        s_cnt <= s_cnt_next;
        sample_a <= sample_a_next;
        bit_done <= bit_done_next;
        rx_done <= rx_done_next;

        if (rst) begin
            state <= IDLE;
            data_idx <= 0;
            s_cnt    <= 0;
            sample_a <= 0;
            rx_done  <= 0;
            bit_done <= 0;
        end
    end

    always @(*) begin
        state_next = state;  // remain in existing state by default
        data_idx_next = data_idx;
        s_cnt_next = s_cnt;
        sample_a_next = sample_a;
        bit_done_next = 0;  // default to 0 (high for one tick only)
        rx_done_next  = 0;

        case(state)
            IDLE: begin  // rx going low signals start
                if (rx == 0) begin
                    state_next = START;
                    s_cnt_next = 0;
                end
            end
            START: begin
                if (stb_16xbaud) begin
                    if (s_cnt == SAMPLE_A && rx == 1) begin
                        state_next = IDLE;  // abort if rx doesn't remain low
                    end else if (s_cnt == SAMPLE_LAST) begin
                        state_next = DATA;
                        data_idx_next = 0;
                        s_cnt_next = 0;
                    end else s_cnt_next = s_cnt + 1;
                end
            end
            DATA: begin
                if (stb_16xbaud) begin
                    if (s_cnt == SAMPLE_A) begin
                        sample_a_next = rx;
                        bit_done_next = 1;  // final sample
                        s_cnt_next = s_cnt + 1;
                    end else if (s_cnt == SAMPLE_LAST) begin
                        if (data_idx == LAST_BIT)
                            state_next = STOP;  // last data bit done?
                        else data_idx_next = data_idx + 1;
                        s_cnt_next = 0;
                    end else s_cnt_next = s_cnt + 1;
                end
            end
            STOP: begin
                if (stb_16xbaud) begin
                    if (s_cnt == SAMPLE_A) begin
                        sample_a_next = rx;
                        s_cnt_next = s_cnt + 1;
                    end else if (s_cnt == SAMPLE_LAST) begin
                        state_next = IDLE;
                        if (sample_a) rx_done_next = 1;  // only done if valid STOP
                    end else s_cnt_next = s_cnt + 1;
                end
            end
        endcase
    end

    always @(posedge clk) begin
        if (bit_done) data_tmp[data_idx] <= sample_a;
        if (rx_done_next) dout <= data_tmp;
        if (rst) begin
            dout <= 0;
            data_tmp <= 0;
        end
    end

    always @(*) rx_busy = (state != IDLE);
endmodule
