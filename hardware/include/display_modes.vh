// Isle.Computer - Display Modes Header
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// modes (pixel clock)
//  0 -  640 x  400 (20.00 MHz)
//  1 - 1280 x  800 (71.00 MHz)
//  2 - 1280 x  720 (74.25 MHz)

// NB. pixel clock must match display mode

// check for invalid mode in simulation
initial begin
    if (DISPLAY_MODE < 0 || DISPLAY_MODE > 2) begin
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
    (DISPLAY_MODE == 1) ? 16'sd1280 :
    (DISPLAY_MODE == 2) ? 16'sd1280 :
    16'sd0;

localparam VRES =
    (DISPLAY_MODE == 0) ?  16'sd400 :
    (DISPLAY_MODE == 1) ?  16'sd800 :
    (DISPLAY_MODE == 2) ?  16'sd720 :
    16'sd0;

localparam BMAP_HRES =
    (DISPLAY_MODE == 0) ? 16'sd640 :
    (DISPLAY_MODE == 1) ? 16'sd640 :
    (DISPLAY_MODE == 2) ? 16'sd640 :
    16'sd0;

localparam BMAP_VRES =
    (DISPLAY_MODE == 0) ? 16'sd400 :
    (DISPLAY_MODE == 1) ? 16'sd400 :
    (DISPLAY_MODE == 2) ? 16'sd400 :
    16'sd0;

localparam H_POL =
    (DISPLAY_MODE == 0) ? 1'b0 :
    (DISPLAY_MODE == 1) ? 1'b1 :
    (DISPLAY_MODE == 2) ? 1'b1 :
    1'b0;

localparam H_STA =
    (DISPLAY_MODE == 0) ? -16'sd160 :
    (DISPLAY_MODE == 1) ? -16'sd320 :
    (DISPLAY_MODE == 2) ? -16'sd370 :
    16'sd0;

localparam HS_STA =
    (DISPLAY_MODE == 0) ? -16'sd144 :
    (DISPLAY_MODE == 1) ? -16'sd296 :
    (DISPLAY_MODE == 2) ? -16'sd260 :
    16'sd0;

localparam HS_END =
    (DISPLAY_MODE == 0) ?  -16'sd80 :
    (DISPLAY_MODE == 1) ? -16'sd160 :
    (DISPLAY_MODE == 2) ? -16'sd220 :
    16'sd0;

localparam HA_STA = 16'sd0;
localparam HA_END = HRES - 16'sd1;

localparam V_POL =
    (DISPLAY_MODE == 0) ? 1'b1 :
    (DISPLAY_MODE == 1) ? 1'b0 :
    (DISPLAY_MODE == 2) ? 1'b1 :
    1'b0;

localparam V_STA =
    (DISPLAY_MODE == 0) ? -16'sd17 :
    (DISPLAY_MODE == 1) ? -16'sd38 :
    (DISPLAY_MODE == 2) ? -16'sd30 :
    16'sd0;

localparam VS_STA =
    (DISPLAY_MODE == 0) ? -16'sd14 :
    (DISPLAY_MODE == 1) ? -16'sd35 :
    (DISPLAY_MODE == 2) ? -16'sd25 :
    16'sd0;

localparam VS_END =
    (DISPLAY_MODE == 0) ?  -16'sd8 :
    (DISPLAY_MODE == 1) ? -16'sd29 :
    (DISPLAY_MODE == 2) ? -16'sd20 :
    16'sd0;

localparam VA_STA = 16'sd0;
localparam VA_END = VRES - 16'sd1;


//
// Default Bitmap and Text Mode Display Parameters
//

localparam WIN_START_CORD =
    (DISPLAY_MODE == 0) ? 32'h00000000 :
    (DISPLAY_MODE == 1) ? 32'h00000000 :
    (DISPLAY_MODE == 2) ? 32'h00000000 :  // consider changing to -40
    32'h0;

localparam WIN_END_CORD =
    (DISPLAY_MODE == 0) ? 32'h01900280 :
    (DISPLAY_MODE == 1) ? 32'h03200500 :
    (DISPLAY_MODE == 2) ? 32'h02D00500 :
    32'h0;

localparam DISPLAY_SCALE =
    (DISPLAY_MODE == 0) ? 32'h00010001 :
    (DISPLAY_MODE == 1) ? 32'h00020002 :
    (DISPLAY_MODE == 2) ? 32'h00020002 :
    32'h0;

/* verilator lint_on UNUSEDPARAM */
