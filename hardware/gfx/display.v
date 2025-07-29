// Isle.Computer - Display Controller
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// display modes (pixel clock)
//  0 -  640 x 480 60 Hz (25.2 MHz) - default
//  1 - 1024 x 768 60 Hz (65 MHz) - recommended 4:3
//  2 - 1366 x 768 60 Hz (72 MHz) - recommended 16:9
//  3 -  672 x 384 60 Hz (25 MHz) - for simulation
//  4 - 1280 x 720 60 Hz (74.25 MHz) - HD

`default_nettype none
`timescale 1ns / 1ps

module display #(
    parameter CORDW=0,  // signed coordinate width (bits)
    parameter MODE=0    // display mode (see above for supported modes)
    ) (
    input  wire clk_pix,                 // pixel clock
    input  wire rst_pix,                 // reset in pixel clock domain
    output reg signed [CORDW-1:0] hres,  // horizontal resolution (pixels)
    output reg signed [CORDW-1:0] vres,  // vertical resolution (lines)
    output reg signed [CORDW-1:0] dx,    // horizontal display position
    output reg signed [CORDW-1:0] dy,    // vertical display position
    output reg hsync,                    // horizontal sync
    output reg vsync,                    // vertical sync
    output reg de,                       // data enable (low in blanking)
    output reg frame_start,              // high for one cycle at frame start
    output reg line_start                // high for one cycle at line start
    );

    reg signed [CORDW-1:0] x, y;  // uncorrected display position (1 cycle early)

    // timing registers
    reg signed [CORDW-1:0] h_sta, hs_sta, hs_end, ha_sta, ha_end;
    reg signed [CORDW-1:0] v_sta, vs_sta, vs_end, va_sta, va_end;
    reg h_pol, v_pol;  // sync polarity (0:neg, 1:pos)

    // generate horizontal and vertical sync with correct polarity
    always @(posedge clk_pix) begin
        hsync <= h_pol ? (x >= hs_sta && x < hs_end) : ~(x >= hs_sta && x < hs_end);
        vsync <= v_pol ? (y >= vs_sta && y < vs_end) : ~(y >= vs_sta && y < vs_end);
        if (rst_pix) begin
            hsync <= h_pol ? 0 : 1;
            vsync <= v_pol ? 0 : 1;
        end
    end

    // control signals
    always @(posedge clk_pix) begin
        de          <= (y >= va_sta && x >= ha_sta);
        frame_start <= (y == v_sta  && x == h_sta);
        line_start  <= (x == h_sta);
        if (rst_pix) begin
            de          <= 0;
            frame_start <= 0;
            line_start  <= 0;
        end
    end

    // calculate horizontal and vertical display position
    always @(posedge clk_pix) begin
        if (x == ha_end) begin  // last pixel on line?
            x <= h_sta;
            y <= (y == va_end) ? v_sta : y + 1;  // last line on display?
        end else begin
            x <= x + 1;
        end
        if (rst_pix) begin
            x <= h_sta;
            y <= v_sta;
        end
    end

    // delay display position to match sync and control signals
    always @(posedge clk_pix) begin
        dx <= x;
        dy <= y;
        if (rst_pix) begin
            dx <= h_sta;
            dy <= v_sta;
        end
    end

    // display timings
    always @(posedge clk_pix) begin
        case (MODE)
            default: begin  // 640 x 480 - default
                hres   <=  640;  // horizontal resolution
                vres   <=  480;  // vertical resolution

                h_pol  <=    0;  // horizontal sync polarity (0:neg, 1:pos)
                h_sta  <= -160;  // horizontal start (horizontal blanking)
                hs_sta <= -144;  // sync start (after front porch)
                hs_end <=  -48;  // sync end
                ha_sta <=    0;  // active start
                ha_end <=  639;  // active end

                v_pol  <=    0;  // vertical sync polarity (0:neg, 1:pos)
                v_sta  <=  -45;  // vertical start (vertical blanking)
                vs_sta <=  -35;  // sync start (after front porch)
                vs_end <=  -33;  // sync end
                va_sta <=    0;  // active start
                va_end <=  479;  // active end
            end
            1: begin  // 1024 x 768
                hres   <= 1024;
                vres   <=  768;

                h_pol  <=    0;
                h_sta  <= -320;
                hs_sta <= -296;
                hs_end <= -160;
                ha_sta <=    0;
                ha_end <= 1023;

                v_pol  <=    0;
                v_sta  <=  -38;
                vs_sta <=  -35;
                vs_end <=  -29;
                va_sta <=    0;
                va_end <=  767;
            end
            2: begin  // 1366 x 768
                hres   <= 1366;
                vres   <=  768;

                h_pol  <=    1;
                h_sta  <= -134;
                hs_sta <= -120;
                hs_end <=  -64;
                ha_sta <=    0;
                ha_end <= 1365;

                v_pol  <=    1;
                v_sta  <=  -32;
                vs_sta <=  -31;
                vs_end <=  -28;
                va_sta <=    0;
                va_end <=  767;
            end
            3: begin  // 672 x 384
                hres   <=  672;
                vres   <=  384;

                h_pol  <=    1;
                h_sta  <= -128;
                hs_sta <= -112;
                hs_end <=  -48;
                ha_sta <=    0;
                ha_end <=  671;

                v_pol  <=    1;
                v_sta  <= -137;
                vs_sta <= -127;
                vs_end <= -125;
                va_sta <=    0;
                va_end <=  383;
            end
            4: begin  // 1280 x 720
                hres   <= 1280;
                vres   <=  720;

                h_pol  <=    1;
                h_sta  <= -370;
                hs_sta <= -260;
                hs_end <= -220;
                ha_sta <=    0;
                ha_end <= 1279;

                v_pol  <=    1;
                v_sta  <=  -30;
                vs_sta <=  -25;
                vs_end <=  -20;
                va_sta <=    0;
                va_end <=  719;
            end
        endcase
    end
endmodule
