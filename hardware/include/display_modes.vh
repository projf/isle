// Isle.Computer - Display Modes Header
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// modes (pixel clock)
//  0 -  640 x  480 ( 25.20 MHz)
//  1 - 1024 x  768 ( 65.00 MHz)
//  2 - 1366 x  768 ( 72.00 MHz)
//  3 -  672 x  384 ( 20.00 MHz) - for simulation
//  4 - 1280 x  720 ( 74.25 MHz)
//  5 - 1920 x 1080 (148.50 MHz)

// NB. pixel clock must match display mode

// check for invalid mode in simulation
initial begin
    if (MODE < 0 || MODE > 5) begin
        $display("ERROR: invalid display MODE = %0d", MODE);
        $finish;
    end
end

/* verilator lint_off UNUSEDPARAM */

//
// display timings
//

localparam HRES =
    (MODE == 0) ?  16'sd640 :
    (MODE == 1) ? 16'sd1024 :
    (MODE == 2) ? 16'sd1366 :
    (MODE == 3) ?  16'sd672 :
    (MODE == 4) ? 16'sd1280 :
    (MODE == 5) ? 16'sd1920 :
    16'sd0;

localparam VRES =
    (MODE == 0) ?  16'sd480 :
    (MODE == 1) ?  16'sd768 :
    (MODE == 2) ?  16'sd768 :
    (MODE == 3) ?  16'sd384 :
    (MODE == 4) ?  16'sd720 :
    (MODE == 5) ? 16'sd1080 :
    16'sd0;

localparam BMAP_HRES =
    (MODE == 0) ? 16'sd640 :
    (MODE == 1) ? 16'sd512 :
    (MODE == 2) ? 16'sd672 :
    (MODE == 3) ? 16'sd672 :
    (MODE == 4) ? 16'sd640 :
    (MODE == 5) ? 16'sd640 :
    16'sd0;

localparam BMAP_VRES =
    (MODE == 0) ? 16'sd360 :
    (MODE == 1) ? 16'sd384 :
    (MODE == 2) ? 16'sd384 :
    (MODE == 3) ? 16'sd384 :
    (MODE == 4) ? 16'sd360 :
    (MODE == 5) ? 16'sd360 :
    16'sd0;

localparam H_POL =
    (MODE == 0) ? 1'b0 :
    (MODE == 1) ? 1'b0 :
    (MODE == 2) ? 1'b1 :
    (MODE == 3) ? 1'b1 :
    (MODE == 4) ? 1'b1 :
    (MODE == 5) ? 1'b1 :
    1'b0;

localparam H_STA =
    (MODE == 0) ? -16'sd160 :
    (MODE == 1) ? -16'sd320 :
    (MODE == 2) ? -16'sd134 :
    (MODE == 3) ? -16'sd153 :
    (MODE == 4) ? -16'sd370 :
    (MODE == 5) ? -16'sd280 :
    16'sd0;

localparam HS_STA =
    (MODE == 0) ? -16'sd144 :
    (MODE == 1) ? -16'sd296 :
    (MODE == 2) ? -16'sd120 :
    (MODE == 3) ? -16'sd130 :
    (MODE == 4) ? -16'sd260 :
    (MODE == 5) ? -16'sd192 :
    16'sd0;

localparam HS_END =
    (MODE == 0) ?  -16'sd48 :
    (MODE == 1) ? -16'sd160 :
    (MODE == 2) ?  -16'sd64 :
    (MODE == 3) ? -16'sd110 :
    (MODE == 4) ? -16'sd220 :
    (MODE == 5) ? -16'sd148 :
    16'sd0;

localparam HA_STA = 16'sd0;
localparam HA_END = HRES - 16'sd1;

localparam V_POL =
    (MODE == 0) ? 1'b0 :
    (MODE == 1) ? 1'b0 :
    (MODE == 2) ? 1'b1 :
    (MODE == 3) ? 1'b1 :
    (MODE == 4) ? 1'b1 :
    (MODE == 5) ? 1'b1 :
    1'b0;

localparam V_STA =
    (MODE == 0) ? -16'sd45 :
    (MODE == 1) ? -16'sd38 :
    (MODE == 2) ? -16'sd32 :
    (MODE == 3) ? -16'sd20 :
    (MODE == 4) ? -16'sd30 :
    (MODE == 5) ? -16'sd45 :
    16'sd0;

localparam VS_STA =
    (MODE == 0) ? -16'sd35 :
    (MODE == 1) ? -16'sd35 :
    (MODE == 2) ? -16'sd31 :
    (MODE == 3) ? -16'sd15 :
    (MODE == 4) ? -16'sd25 :
    (MODE == 5) ? -16'sd41 :
    16'sd0;

localparam VS_END =
    (MODE == 0) ? -16'sd33 :
    (MODE == 1) ? -16'sd29 :
    (MODE == 2) ? -16'sd28 :
    (MODE == 3) ? -16'sd10 :
    (MODE == 4) ? -16'sd20 :
    (MODE == 5) ? -16'sd36 :
    16'sd0;

localparam VA_STA = 16'sd0;
localparam VA_END = VRES - 16'sd1;


//
// initial display window and scaling
//

localparam WIN_START_INIT =
    (MODE == 0) ? 32'h003C0000 :
    (MODE == 1) ? 32'h00000000 :
    (MODE == 2) ? 32'h0000000B :
    (MODE == 3) ? 32'h00000000 :
    (MODE == 4) ? 32'h00000000 :
    (MODE == 5) ? 32'h00000000 :
    32'h0;

localparam WIN_END_INIT =
    (MODE == 0) ? 32'h01A40280 :
    (MODE == 1) ? 32'h03000400 :
    (MODE == 2) ? 32'h0300054B :
    (MODE == 3) ? 32'h018002A0 :
    (MODE == 4) ? 32'h02D00500 :
    (MODE == 5) ? 32'h04380780 :
    32'h0;

localparam TEXT_SCALE_INIT =
    (MODE == 0) ? 32'h00010001 :
    (MODE == 1) ? 32'h00020002 :
    (MODE == 2) ? 32'h00020002 :
    (MODE == 3) ? 32'h00010001 :
    (MODE == 4) ? 32'h00020002 :
    (MODE == 5) ? 32'h00030003 :
    32'h0;

localparam CANV_SCALE_INIT =
    (MODE == 0) ? 32'h00020002 :
    (MODE == 1) ? 32'h00040004 :
    (MODE == 2) ? 32'h00040004 :
    (MODE == 3) ? 32'h00020002 :
    (MODE == 4) ? 32'h00040004 :
    (MODE == 5) ? 32'h00060006 :
    32'h0;

/* verilator lint_on UNUSEDPARAM */
