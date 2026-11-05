// Isle.Computer - Display Modes Header
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// modes (pixel clock)
//  0 -  640 x 360 (20.00 MHz) for simulation
//  1 - 1280 x 720 (74.25 MHz)

// NB. pixel clock must match display mode

// check for invalid mode in simulation
initial begin
    if (DISPLAY_MODE < 0 || DISPLAY_MODE > 1) begin
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
    16'sd0;

localparam VRES =
    (DISPLAY_MODE == 0) ?  16'sd360 :
    (DISPLAY_MODE == 1) ?  16'sd720 :
    16'sd0;

localparam H_POL =
    (DISPLAY_MODE == 0) ? 1'b1 :
    (DISPLAY_MODE == 1) ? 1'b1 :
    1'b0;

localparam H_STA =
    (DISPLAY_MODE == 0) ? -16'sd248 :
    (DISPLAY_MODE == 1) ? -16'sd370 :
    16'sd0;

localparam HS_STA =
    (DISPLAY_MODE == 0) ? -16'sd216 :
    (DISPLAY_MODE == 1) ? -16'sd260 :
    16'sd0;

localparam HS_END =
    (DISPLAY_MODE == 0) ? -16'sd120 :
    (DISPLAY_MODE == 1) ? -16'sd220 :
    16'sd0;

localparam HA_STA = 16'sd0;
localparam HA_END = HRES - 16'sd1;

localparam V_POL =
    (DISPLAY_MODE == 0) ? 1'b1 :
    (DISPLAY_MODE == 1) ? 1'b1 :
    1'b0;

localparam V_STA =
    (DISPLAY_MODE == 0) ? -16'sd15 :
    (DISPLAY_MODE == 1) ? -16'sd30 :
    16'sd0;

localparam VS_STA =
    (DISPLAY_MODE == 0) ? -16'sd12 :
    (DISPLAY_MODE == 1) ? -16'sd25 :
    16'sd0;

localparam VS_END =
    (DISPLAY_MODE == 0) ?  -16'sd7 :
    (DISPLAY_MODE == 1) ? -16'sd20 :
    16'sd0;

localparam VA_STA = 16'sd0;
localparam VA_END = VRES - 16'sd1;


//
// Default Bitmap and Text Mode Display Parameters
//

localparam WIN_START_CORD =
    (DISPLAY_MODE == 0) ? 32'h00040000 :
    (DISPLAY_MODE == 1) ? 32'h00080000 :
    32'h0;

localparam WIN_END_CORD =
    (DISPLAY_MODE == 0) ? 32'h01600000 :
    (DISPLAY_MODE == 1) ? 32'h02C00000 :
    32'h0;

localparam DISPLAY_SCALE =
    (DISPLAY_MODE == 0) ? 32'h00010001 :
    (DISPLAY_MODE == 1) ? 32'h00020002 :
    32'h0;

/* verilator lint_on UNUSEDPARAM */
