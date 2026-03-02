// Isle.Computer - xN1 UART Transmitter
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

// default params configured for 115200 baud with 20 MHz system clock

module uart_tx #(
    parameter UART_CNT_INC=6036,  // 16 x baud counter increment
    parameter UART_CNT_W=16,      // 16 x baud counter width (bits)
    parameter UART_DATAW=8        // UART data width (bits)
    ) (
    input  wire clk,         // clock
    input  wire rst,         // reset
    input  wire tx_start,    // start transmission
    input  wire [UART_DATAW-1:0] din,  // data to transmit
    output reg  serial_out,  // serial data out
    output reg  tx_busy,     // busy transmitting
    output reg  tx_done      // transmit complete
    );

    // baud strobe generator
    reg stb_baud;
    reg [UART_CNT_W+3:0] cnt_baud;  // +3 as baud is 16x slower than sample rate
    always @(posedge clk) begin
        {stb_baud, cnt_baud} <= cnt_baud + UART_CNT_INC;

        if (rst) begin
            stb_baud <= 0;
            cnt_baud <= 0;
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
    localparam LAST_BIT = UART_DATAW - 1;

    reg tx_start_flag;    // register start signal
    reg serial_out_next;  // next bit of output
    reg [UART_DATAW-1:0] data_in_reg;  // registered din

    always @(posedge clk) begin
        // register din at tx_start
        if (state == IDLE && tx_start && !tx_start_flag) data_in_reg <= din;

        if (tx_start) tx_start_flag <= 1;
        else if (state == START) tx_start_flag <= 0;

        tx_done <= 0;
        serial_out <= serial_out_next;

        if (stb_baud) begin
            state <= state_next;
            data_idx <= data_idx_next;
            if (state == STOP) tx_done <= 1;
        end

        if (rst) begin
            state <= IDLE;
            data_idx <= 0;
            serial_out <= 1'b1;  // UART default is high
            tx_done <= 0;
            data_in_reg <= 0;
            tx_start_flag <= 0;
        end
    end

    always @(*) begin
        state_next = IDLE;
        data_idx_next = 0;
        serial_out_next = 1'b1;  // serial line is high by default

        case(state)
            IDLE: state_next = (tx_start_flag) ? START : IDLE;
            START: begin
                serial_out_next = 1'b0;  // signal goes low to signify start
                state_next = DATA;
            end
            DATA: begin
                serial_out_next = data_in_reg[data_idx];
                data_idx_next = data_idx + 1;
                /* verilator lint_off WIDTHEXPAND */
                state_next = (data_idx == LAST_BIT) ? STOP : DATA;
                /* verilator lint_on WIDTHEXPAND */
            end
            STOP: state_next = IDLE;
        endcase
    end

    always @(*) tx_busy = (state != IDLE);
endmodule
