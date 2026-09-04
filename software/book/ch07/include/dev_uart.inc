# Isle.Computer - Uart Device (Chapter 7)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# uart device (rx is to Isle)
.equ UART_RX_EN,      0x0100  # enable uart rx into fifo
.equ UART_RX_DAT_RO,  0x0104  # uart rx data via fifo
.equ UART_RX_DEP_RO,  0x0108  # uart rx fifo depth
.equ UART_RX_LEN_RO,  0x010C  # uart rx fifo length (items)
.equ UART_RX_OVF_RO,  0x0110  # uart rx fifo overflow flag
.equ UART_RX_OVF_CLR, 0x0114  # clear rx fifo overflow flag (strobe)

.equ UART_EOF, -1  # EOF for UART reads
