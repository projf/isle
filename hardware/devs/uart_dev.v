// Isle.Computer - Device: UART
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

// Isle can receive uart data in the current uart_dev, but not send it
// default params configured for 115200 baud with 20 MHz system clock
// UART_FIFO_RX_ADDRW=4 give 15 fifo entries (2^4 - 1)

module uart_dev #(
    parameter DEV_ADDRW=10,          // device address width (bits)
    parameter UART_CNT_INC=6036,     // 16 x baud counter increment
    parameter UART_CNT_W=16,         // 16 x baud counter width (bits)
    parameter UART_DATAW=8,          // UART data width (bits)
    parameter UART_FIFO_RX_ADDRW=4,  // RX fifo address width (bits)
    parameter WORD=32                // machine word size (bits)
    ) (
    input  wire clk,  // clock
    input  wire rst,  // reset
    input  wire we,   // write enable
    input  wire re,   // read enable
    input  wire [DEV_ADDRW-1:0] addr,  // address
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire [WORD-1:0] din,  // data in
    /* verilator lint_on UNUSEDSIGNAL */
    output reg  [WORD-1:0] dout,  // data out
    output wire rbusy,  // UART busy reading
    // external I/O signals
    input  wire uart_rx,  // UART receive to Isle
    output wire uart_tx   // UART transmit from Isle
    );

    // HW_REG_ADDR - must match software
    localparam [DEV_ADDRW-1:0] UART_RX_EN  = 'h100 >> 2;  // word addressing
    localparam [DEV_ADDRW-1:0] UART_RX_DAT = 'h104 >> 2;
    localparam [DEV_ADDRW-1:0] UART_RX_DEP = 'h108 >> 2;
    localparam [DEV_ADDRW-1:0] UART_RX_LEN = 'h10C >> 2;
    // END_HW_REG_ADDR

    // uart signals
    wire [UART_DATAW-1:0] rx_data;
    wire rx_done;

    assign uart_tx = 1;  // TX disabled: hold line idle

    // RX fifo signals
    reg rx_fifo_en;  // controls whether the fifo reads from UART
    wire rx_fifo_we = rx_fifo_en && rx_done;
    wire rx_fifo_re = re && !rx_fifo_empty && (addr == UART_RX_DAT);
    wire [UART_DATAW-1:0] rx_fifo_din = rx_data;
    wire [UART_DATAW-1:0] rx_fifo_dout;
    wire [UART_FIFO_RX_ADDRW-1:0] rx_fifo_len;
    wire rx_fifo_empty;

    reg uart_rx_rdy;  // flag for RX read ready (takes one cycle)
    assign rbusy = uart_rx_rdy;  // we're busy for one cycle, reading from fifo

    // HW Reg MMIO
    always @(posedge clk) begin
        dout <= 0;  // no data out unless enabled

        if (re) begin
            case (addr)
                UART_RX_DAT: if (!rx_fifo_empty) uart_rx_rdy <= 1;  // if not empty, read next cycle
                UART_RX_DEP: dout <= 2**UART_FIFO_RX_ADDRW - 1;
                UART_RX_LEN: dout <= {{WORD - UART_FIFO_RX_ADDRW{1'b0}}, rx_fifo_len};
                default: dout <= 0;
            endcase
        end
        if (we) begin
            if (addr == UART_RX_EN) rx_fifo_en <= din[0];  // only considers LSB
        end

        if (rst) rx_fifo_en <= 0;  // rx_fifo_en is used with rx_fifo.rst

        // read data from fifo the following clock cycle
        if (uart_rx_rdy) begin
            dout <= {{WORD - UART_DATAW{1'b0}}, rx_fifo_dout};
            uart_rx_rdy <= 0;
        end
    end

    fifo_sync #(
        .ADDRW(UART_FIFO_RX_ADDRW),
        .DATAW(UART_DATAW)
    ) rx_fifo (
        .clk(clk),
        .rst(rst || !rx_fifo_en),  // ensure fifo is empty when enabled
        .we(rx_fifo_we),
        .re(rx_fifo_re),
        .din(rx_fifo_din),
        .dout(rx_fifo_dout),
        .len(rx_fifo_len),
        .empty(rx_fifo_empty),
        /* verilator lint_off PINCONNECTEMPTY */
        .full()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    uart_rx #(
        .UART_CNT_W(UART_CNT_W),
        .UART_CNT_INC(UART_CNT_INC),
        .UART_DATAW(UART_DATAW)
    ) uart_rx_inst (
        .clk(clk),
        .rst(rst),
        .serial_in(uart_rx),
        .dout(rx_data),
        /* verilator lint_off PINCONNECTEMPTY */
        .rx_busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .rx_done(rx_done)
    );
endmodule
