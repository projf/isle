// Isle.Computer - XC7 TMDS Signal Output
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module tmds_out (
    input  wire tmds,   // TMDS signal
    output wire pin_p,  // positive differential signal pin
    output wire pin_n   // negative differential signal pin
    );

    OBUFDS #(.IOSTANDARD("TMDS_33")) tmds_obufds (.I(tmds), .O(pin_p), .OB(pin_n));
endmodule
