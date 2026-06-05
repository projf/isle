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
    if (DISPLAY_MODE < 0 || DISPLAY_MODE > 5) begin
        $display("ERROR: invalid display DISPLAY_MODE = %0d", DISPLAY_MODE);
        $finish;
    end
end

/* verilator lint_off UNUSEDPARAM */

//
// Display Timings
//

localparam HRES =
    (DISPLAY_MODE == 0) ?  16'sd640 :
    (DISPLAY_MODE == 1) ? 16'sd1024 :
    (DISPLAY_MODE == 2) ? 16'sd1366 :
    (DISPLAY_MODE == 3) ?  16'sd672 :
    (DISPLAY_MODE == 4) ? 16'sd1280 :
    (DISPLAY_MODE == 5) ? 16'sd1920 :
    16'sd0;

localparam VRES =
    (DISPLAY_MODE == 0) ?  16'sd480 :
    (DISPLAY_MODE == 1) ?  16'sd768 :
    (DISPLAY_MODE == 2) ?  16'sd768 :
    (DISPLAY_MODE == 3) ?  16'sd384 :
    (DISPLAY_MODE == 4) ?  16'sd720 :
    (DISPLAY_MODE == 5) ? 16'sd1080 :
    16'sd0;

localparam BMAP_HRES =
    (DISPLAY_MODE == 0) ? 16'sd640 :
    (DISPLAY_MODE == 1) ? 16'sd512 :
    (DISPLAY_MODE == 2) ? 16'sd672 :
    (DISPLAY_MODE == 3) ? 16'sd672 :
    (DISPLAY_MODE == 4) ? 16'sd640 :
    (DISPLAY_MODE == 5) ? 16'sd640 :
    16'sd0;

localparam BMAP_VRES =
    (DISPLAY_MODE == 0) ? 16'sd360 :
    (DISPLAY_MODE == 1) ? 16'sd384 :
    (DISPLAY_MODE == 2) ? 16'sd384 :
    (DISPLAY_MODE == 3) ? 16'sd384 :
    (DISPLAY_MODE == 4) ? 16'sd360 :
    (DISPLAY_MODE == 5) ? 16'sd360 :
    16'sd0;

localparam H_POL =
    (DISPLAY_MODE == 0) ? 1'b0 :
    (DISPLAY_MODE == 1) ? 1'b0 :
    (DISPLAY_MODE == 2) ? 1'b1 :
    (DISPLAY_MODE == 3) ? 1'b1 :
    (DISPLAY_MODE == 4) ? 1'b1 :
    (DISPLAY_MODE == 5) ? 1'b1 :
    1'b0;

localparam H_STA =
    (DISPLAY_MODE == 0) ? -16'sd160 :
    (DISPLAY_MODE == 1) ? -16'sd320 :
    (DISPLAY_MODE == 2) ? -16'sd134 :
    (DISPLAY_MODE == 3) ? -16'sd153 :
    (DISPLAY_MODE == 4) ? -16'sd370 :
    (DISPLAY_MODE == 5) ? -16'sd280 :
    16'sd0;

localparam HS_STA =
    (DISPLAY_MODE == 0) ? -16'sd144 :
    (DISPLAY_MODE == 1) ? -16'sd296 :
    (DISPLAY_MODE == 2) ? -16'sd120 :
    (DISPLAY_MODE == 3) ? -16'sd130 :
    (DISPLAY_MODE == 4) ? -16'sd260 :
    (DISPLAY_MODE == 5) ? -16'sd192 :
    16'sd0;

localparam HS_END =
    (DISPLAY_MODE == 0) ?  -16'sd48 :
    (DISPLAY_MODE == 1) ? -16'sd160 :
    (DISPLAY_MODE == 2) ?  -16'sd64 :
    (DISPLAY_MODE == 3) ? -16'sd110 :
    (DISPLAY_MODE == 4) ? -16'sd220 :
    (DISPLAY_MODE == 5) ? -16'sd148 :
    16'sd0;

localparam HA_STA = 16'sd0;
localparam HA_END = HRES - 16'sd1;

localparam V_POL =
    (DISPLAY_MODE == 0) ? 1'b0 :
    (DISPLAY_MODE == 1) ? 1'b0 :
    (DISPLAY_MODE == 2) ? 1'b1 :
    (DISPLAY_MODE == 3) ? 1'b1 :
    (DISPLAY_MODE == 4) ? 1'b1 :
    (DISPLAY_MODE == 5) ? 1'b1 :
    1'b0;

localparam V_STA =
    (DISPLAY_MODE == 0) ? -16'sd45 :
    (DISPLAY_MODE == 1) ? -16'sd38 :
    (DISPLAY_MODE == 2) ? -16'sd32 :
    (DISPLAY_MODE == 3) ? -16'sd20 :
    (DISPLAY_MODE == 4) ? -16'sd30 :
    (DISPLAY_MODE == 5) ? -16'sd45 :
    16'sd0;

localparam VS_STA =
    (DISPLAY_MODE == 0) ? -16'sd35 :
    (DISPLAY_MODE == 1) ? -16'sd35 :
    (DISPLAY_MODE == 2) ? -16'sd31 :
    (DISPLAY_MODE == 3) ? -16'sd15 :
    (DISPLAY_MODE == 4) ? -16'sd25 :
    (DISPLAY_MODE == 5) ? -16'sd41 :
    16'sd0;

localparam VS_END =
    (DISPLAY_MODE == 0) ? -16'sd33 :
    (DISPLAY_MODE == 1) ? -16'sd29 :
    (DISPLAY_MODE == 2) ? -16'sd28 :
    (DISPLAY_MODE == 3) ? -16'sd10 :
    (DISPLAY_MODE == 4) ? -16'sd20 :
    (DISPLAY_MODE == 5) ? -16'sd36 :
    16'sd0;

localparam VA_STA = 16'sd0;
localparam VA_END = VRES - 16'sd1;


//
// Default Bitmap and Text Mode Display Parameters
//

localparam WIN_START_INIT =
    (DISPLAY_MODE == 0) ? 32'h003C0000 :
    (DISPLAY_MODE == 1) ? 32'h00000000 :
    (DISPLAY_MODE == 2) ? 32'h0000000B :
    (DISPLAY_MODE == 3) ? 32'h00000000 :
    (DISPLAY_MODE == 4) ? 32'h00000000 :
    (DISPLAY_MODE == 5) ? 32'h00000000 :
    32'h0;

localparam WIN_END_INIT =
    (DISPLAY_MODE == 0) ? 32'h01A40280 :
    (DISPLAY_MODE == 1) ? 32'h03000400 :
    (DISPLAY_MODE == 2) ? 32'h0300054B :
    (DISPLAY_MODE == 3) ? 32'h018002A0 :
    (DISPLAY_MODE == 4) ? 32'h02D00500 :
    (DISPLAY_MODE == 5) ? 32'h04380780 :
    32'h0;

localparam [CORDW-1:0] DISPLAY_SCALE =
    (DISPLAY_MODE == 0) ? 16'd1 :
    (DISPLAY_MODE == 1) ? 16'd2 :
    (DISPLAY_MODE == 2) ? 16'd2 :
    (DISPLAY_MODE == 3) ? 16'd1 :
    (DISPLAY_MODE == 4) ? 16'd2 :
    (DISPLAY_MODE == 5) ? 16'd3 :
    16'h0;

/* verilator lint_on UNUSEDPARAM */
