# Isle.Computer - Uart Device (Chapter 7)
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# uart device (rx is to Isle)
.equ UART_RX_EN,  0x0100  # enable uart rx into fifo
.equ UART_RX_DAT, 0x0104  # uart rx data via fifo
.equ UART_RX_DEP, 0x0108  # uart rx fifo depth
.equ UART_RX_LEN, 0x010C  # uart rx fifo length (items)

.equ UART_EOF, 0xFFFFFFFF  # -1 is EOF for UART reads
