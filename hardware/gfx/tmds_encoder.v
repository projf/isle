// Isle.Computer - TMDS Encoder (DVI)
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module tmds_encoder (
    input  wire clk_pix,        // pixel clock
    input  wire rst_pix,        // reset in pixel clock domain
    input  wire [7:0] din,      // colour data
    input  wire [1:0] ctrl_in,  // control data
    input  wire de,             // data enable
    output reg [9:0] tmds       // encoded TMDS data
    );

    // select basic encoding based on the number of ones in the input data
    reg [3:0] data_1s;
    reg use_xnor;
    always @(*) begin
        /* verilator lint_off WIDTH */
        data_1s = din[0] + din[1] + din[2] + din[3]
                + din[4] + din[5] + din[6] + din[7];
        /* verilator lint_on WIDTH */
        use_xnor = (data_1s > 4'd4) || ((data_1s == 4'd4) && (din[0] == 0));
    end
     
    // encode colour data with xor/xnor
    integer i;
    reg [8:0] enc_qm;
    always @(*) begin
        enc_qm[0] = din[0];
        for (i=0; i<7; i=i+1) begin
            enc_qm[i+1] = (use_xnor) ? (enc_qm[i] ~^ din[i+1]) : (enc_qm[i] ^ din[i+1]);
        end
        enc_qm[8] = (use_xnor) ? 0 : 1;
    end

    // disparity in encoded data for DC balancing: needs to cover -8 to +8
    reg signed [4:0] ones, zeros, balance;
    always @(*) begin
        /* verilator lint_off WIDTH */
        ones = enc_qm[0] + enc_qm[1] + enc_qm[2] + enc_qm[3] + 
                    enc_qm[4] + enc_qm[5] + enc_qm[6] + enc_qm[7];
        /* verilator lint_on WIDTH */
        zeros   = 5'd8 - ones;
        balance = ones - zeros;
    end

    // record ongoing DC bias
    reg signed [4:0] bias;
    always @(posedge clk_pix) begin
        if (de == 0) begin  // send control data in blanking interval
            case (ctrl_in)  // ctrl sequences (always have 7 transitions)
                2'b00:   tmds <= 10'b1101010100;
                2'b01:   tmds <= 10'b0010101011;
                2'b10:   tmds <= 10'b0101010100;
                default: tmds <= 10'b1010101011;
            endcase
            bias <= 5'sb00000;
        end else begin  // send pixel colour data (at most 5 transitions)
            if (bias == 0 || balance == 0) begin  // no prior bias or disparity
                if (enc_qm[8] == 0) begin
                    tmds[9:0] <= {2'b10, ~enc_qm[7:0]};
                    bias <= bias - balance;
                end else begin
                    tmds[9:0] <= {2'b01, enc_qm[7:0]};
                    bias <= bias + balance;
                end
            end
            else if ((bias > 0 && balance > 0) || (bias < 0 && balance < 0)) begin
                tmds[9:0] <= {1'b1, enc_qm[8], ~enc_qm[7:0]};
                bias <= bias + {3'b0, enc_qm[8], 1'b0} - balance;
            end else begin
                tmds[9:0] <= {1'b0, enc_qm[8], enc_qm[7:0]};
                bias <= bias - {3'b0, ~enc_qm[8], 1'b0} + balance;
            end
        end

        if (rst_pix) begin
            tmds <= 10'b1101010100;  // equivalent to ctrl 2'b00
            bias <= 5'sb00000;
        end
    end
endmodule
