// Isle.Computer - UART Device
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

// Isle can receive uart data in the current dev_uart, but not send it
// default params configured for 115200 baud with 20 MHz system clock
// UART_FIFO_RX_ADDRW=4 gives 15 fifo entries (2^4 - 1)

module dev_uart #(
    parameter DEV_ADDRW=14,          // device address width (bits)
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
    output wire rbusy,  // device busy reading
    // external I/O signals
    input  wire uart_rx,  // UART receive to Isle
    output wire uart_tx   // UART transmit from Isle
    );

    // HWREG_ADDR - must match software - word addressing (hence right shift)
    localparam [DEV_ADDRW-1:0] UART_RX_EN      = 'h100 >> 2;
    localparam [DEV_ADDRW-1:0] UART_RX_DAT_RO  = 'h104 >> 2;
    localparam [DEV_ADDRW-1:0] UART_RX_DEP_RO  = 'h108 >> 2;
    localparam [DEV_ADDRW-1:0] UART_RX_LEN_RO  = 'h10C >> 2;
    localparam [DEV_ADDRW-1:0] UART_RX_OVF_RO  = 'h110 >> 2;
    localparam [DEV_ADDRW-1:0] UART_RX_OVF_CLR = 'h114 >> 2;
    // END_HWREG_ADDR

    localparam [WORD-1:0] UART_EOF = {WORD{1'b1}};  // -1: must match software

    // uart signals
    wire [UART_DATAW-1:0] rx_data;
    wire rx_done;
    wire rx_fifo_full;

    // RX fifo signals
    reg rx_fifo_en;  // controls whether the fifo reads from UART
    wire rx_fifo_empty;
    wire rx_fifo_we = rx_fifo_en && rx_done;
    wire rx_fifo_re = re && !rx_fifo_empty && (addr == UART_RX_DAT_RO);
    wire [UART_DATAW-1:0] rx_fifo_din = rx_data;
    wire [UART_DATAW-1:0] rx_fifo_dout;
    wire rx_fifo_dout_valid;
    wire [UART_FIFO_RX_ADDRW-1:0] rx_fifo_len;

    assign uart_tx = 1;  // TX disabled for now: hold line idle
    assign rbusy = rx_fifo_re || rx_fifo_dout_valid;  // we're busy until fifo dout is valid

    // RX overflow
    wire rx_ovf_clr = (we && addr == UART_RX_OVF_CLR);  // clear overflow flag (strobe)
    reg rx_ovf;
    always @(posedge clk) begin
        if (rx_fifo_we && rx_fifo_full) rx_ovf <= 1;  // set wins over clear
        else if (rx_ovf_clr)            rx_ovf <= 0;
        if (rst || !rx_fifo_en)         rx_ovf <= 0;  // disabling rx discards, so clear overflow
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
        .dout_valid(rx_fifo_dout_valid),
        .len(rx_fifo_len),
        .empty(rx_fifo_empty),
        .full(rx_fifo_full)
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

    // HW Reg MMIO
    always @(posedge clk) begin
        if (rst) begin
            rx_fifo_en <= 0;  // rx_fifo_en is used with rx_fifo.rst
            dout <= 0;
        end else if (rx_fifo_dout_valid) begin  // second stage of fifo read
            dout <= {{WORD-UART_DATAW{1'b0}}, rx_fifo_dout};
        end else if (re) begin
            case (addr)
                UART_RX_EN:     dout <= {{WORD-1{1'b0}}, rx_fifo_en};
                UART_RX_DAT_RO: dout <= UART_EOF;
                UART_RX_DEP_RO: dout <= 2**UART_FIFO_RX_ADDRW - 1;
                UART_RX_LEN_RO: dout <= {{WORD - UART_FIFO_RX_ADDRW{1'b0}}, rx_fifo_len};
                UART_RX_OVF_RO: dout <= {{WORD-1{1'b0}}, rx_ovf};
                default: dout <= 0;
            endcase
        end else if (we) begin
            if (addr == UART_RX_EN) rx_fifo_en <= din[0];  // only uses bit 0 to enable
        end
    end
endmodule
