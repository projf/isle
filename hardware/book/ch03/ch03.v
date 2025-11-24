// Isle.Computer - Chapter 3: 2D Graphics
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module ch03 #(
    parameter BPC=5,              // bits per colour channel
    parameter CORDW=16,           // signed coordinate width (bits)
    parameter DISPLAY_MODE=0,     // display mode (see display.v for modes)
    parameter BG_COLR=0,          // background colour (RGB555)
    parameter FILE_BMAP="",       // initial bitmap file for vram
    parameter FILE_PAL="",        // initial palette for CLUT
    parameter FILE_ER_LIST="",    // initial command list for Earthrise
    parameter CANV_BPP=0,         // canvas bits per pixel (4=16 colours)
    parameter CANV_WIDTH=16'd0,   // canvas width (pixels)
    parameter CANV_HEIGHT=16'd0,  // canvas height (lines)
    parameter CANV_SCALE=16'd0,   // canvas scaling factor
    parameter WIN_WIDTH=16'd0,    // canvas window width (pixel)
    parameter WIN_HEIGHT=16'd0,   // canvas window height (lines)
    parameter WIN_STARTX=16'd0,   // canvas window horizontal position (pixels)
    parameter WIN_STARTY=16'd0    // canvas window vertical position (lines)
    ) (
    input  wire clk_sys,                    // system clock
    input  wire clk_pix,                    // pixel clock (used by display)
    input  wire rst_sys,                    // reset (system clock domain)
    input  wire rst_pix,                    // reset (pixel clock domain)
    output reg  signed [CORDW-1:0] disp_x,  // horizontal display position
    output reg  signed [CORDW-1:0] disp_y,  // vertical display position
    output reg  disp_hsync,                 // horizontal display sync
    output reg  disp_vsync,                 // vertical display sync
    output reg  disp_de,                    // display data enable
    output reg  disp_frame,                 // high for one cycle at frame start
    output reg  [BPC-1:0] disp_r,           // red display channel
    output reg  [BPC-1:0] disp_g,           // green display channel
    output reg  [BPC-1:0] disp_b            // blue display channel
    );

    `define DEBUG  // debug messages in simulation (comment out to disable)

    // vram - 16K x 32-bit (64 KiB) with bit write
    //   NB. Due to bit write, minimum depth is 64 KiB with 18 Kb bram
    localparam VRAM_ADDRW = 14;  // vram address width (bits)

    // internal system params
    localparam WORD = 32;  // machine word size (bits)
    localparam BYTE =  8;  // machine byte size (bits)
    localparam BYTE_CNT = WORD / BYTE;  // bytes in word (for write enable)
    localparam CIDX_ADDRW = 8;   // colour index address width 2^8 = 256 colours
    localparam COLRW = 3 * BPC;  // colour width across three channels (bits)
    localparam CANV_SHIFTW = 3;  // max shift is 5 bits (2^5 = 32 bits)
    localparam PIX_IDW=$clog2(WORD);  // pixel ID width (bits)

    // display signals
    wire signed [CORDW-1:0] dx, dy;
    wire hsync, vsync, de;
    wire frame_start, line_start;
    wire frame_start_sys;  // frame_start in system clock domain


    //
    // Earthrise Command List
    //

    localparam ER_ADDRW = 10;  // 1024 x 32-bit (4 KiB word addressed)

    wire [ER_ADDRW-1:0]  erlist_addr_er;
    wire [WORD-1:0] erlist_dout_er;

    erlist #(
        .BYTE(BYTE),
        .BYTE_CNT(BYTE_CNT),
        .WORD(WORD),
        .ADDRW(ER_ADDRW),
        .FILE_INIT(FILE_ER_LIST)
    ) erlist_inst (
        .clk(clk_sys),
        /* verilator lint_off PINCONNECTEMPTY */
        .we_sys(),  // for future CPU use
        .addr_sys(),
        .din_sys(),
        .dout_sys(),
        /* verilator lint_on PINCONNECTEMPTY */
        .addr_er(erlist_addr_er),
        .dout_er(erlist_dout_er)
    );


    //
    // Earthrise
    //

    wire [VRAM_ADDRW-1:0] draw_addr;
    wire [CANV_SHIFTW-1:0] draw_addr_shift;  // address shift based on canvas bits per pixel
    /* verilator lint_off UNUSEDSIGNAL */  // lower bits unused because of byte addressing
    wire [ER_ADDRW+1:0] er_pc;  // Earthrise program counter (byte addressed)
    /* verilator lint_on UNUSEDSIGNAL */

    assign erlist_addr_er = er_pc[ER_ADDRW+1:2];  // command list is word addressed

    // CANV_BPP is currently a parameter, but will be hardware register later
    /* verilator lint_off WIDTHTRUNC */
    assign draw_addr_shift = 5 - $clog2(CANV_BPP);
    /* verilator lint_on WIDTHTRUNC */

    // execute Earthrise command list once
    wire er_done;
    reg er_enable;
    always @(posedge clk_sys) begin
        if (rst_sys) er_enable <= 1;
        if (er_done) er_enable <= 0;
    end

    earthrise #(
        .CORDW(CORDW),
        .WORD(WORD),
        .CANV_SHIFTW(CANV_SHIFTW),
        .COLRW(CIDX_ADDRW),
        .ER_ADDRW(ER_ADDRW),
        .VRAM_ADDRW(VRAM_ADDRW)
    ) earthrise_inst (
        .clk(clk_sys),
        .rst(rst_sys),
        .start(frame_start_sys && er_enable),  // start every frame in this simple example
        .canv_w(CANV_WIDTH),
        .canv_h(CANV_HEIGHT),
        .canv_bpp(CANV_BPP),
        .cmd_list(erlist_dout_er),
        .pc(er_pc),
        .addr_base(0),  // fixed until we have CPU
        .addr_shift(draw_addr_shift),
        .vram_addr(draw_addr),
        .vram_din(vram_din_sys),
        .vram_wmask(vram_wmask_sys),
        .done(er_done),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy(),
        .instr_invalid()
        /* verilator lint_on PINCONNECTEMPTY */
    );


    //
    // Video RAM (vram)
    //

    wire [VRAM_ADDRW-1:0] vram_addr_sys;
    wire [WORD-1:0] vram_wmask_sys;
    wire [WORD-1:0] vram_din_sys;
    wire [VRAM_ADDRW-1:0] vram_addr_disp;  // pixel clock domain
    wire [WORD-1:0] vram_dout_disp;  // pixel clock domain

    // use Earthrise address for vram (will multiplex with CPU later)
    assign vram_addr_sys = draw_addr;  // doesn't validate address, but vram depth is power of two

    vram #(
        .WORD(WORD),
        .ADDRW(VRAM_ADDRW),
        .FILE_BMAP(FILE_BMAP)
        ) vram_inst (
        .clk_sys(clk_sys),
        .clk_pix(clk_pix),
        .wmask_sys(vram_wmask_sys),
        .addr_sys(vram_addr_sys),
        .din_sys(vram_din_sys),
        /* verilator lint_off PINCONNECTEMPTY */
        .dout_sys(),  // Earthrise doesn't read vram yet
        /* verilator lint_on PINCONNECTEMPTY */
        .addr_disp(vram_addr_disp),
        .dout_disp(vram_dout_disp)
    );


    //
    // Canvas Display Address
    //

    localparam BMAP_LAT = 6;  // bitmap display latency: agu(2) + vram(2) + clut(2)
    wire [CANV_SHIFTW-1:0] disp_addr_shift;  // address shift based on canvas bits per pixel
    wire [VRAM_ADDRW-1:0] disp_addr;  // pixel memory address
    wire [$clog2(WORD)-1:0] disp_pix_id;  // pixel ID within word
    wire canv_paint;

    // CANV_BPP is currently a parameter, but will be hardware register later
    /* verilator lint_off WIDTHTRUNC */
    assign disp_addr_shift = 5 - $clog2(CANV_BPP);
    /* verilator lint_on WIDTHTRUNC */

    canv_disp_agu #(
        .CORDW(CORDW),
        .WORD(WORD),
        .ADDRW(VRAM_ADDRW),
        .BMAP_LAT(BMAP_LAT),
        .SHIFTW(CANV_SHIFTW)
    ) canv_disp_agu_inst (
        .clk_pix(clk_pix),
        .rst_pix(rst_pix),
        .frame_start(frame_start),
        .line_start(line_start),
        .dx(dx),
        .dy(dy),
        .addr_base(0),  // fixed base address for now
        .addr_shift(disp_addr_shift),
        .win_start({WIN_STARTY, WIN_STARTX}),
        .win_end({WIN_HEIGHT + WIN_STARTY, WIN_WIDTH + WIN_STARTX}),
        .scale({CANV_SCALE, CANV_SCALE}),
        .addr(disp_addr),
        .pix_id(disp_pix_id),
        .paint(canv_paint)
    );


    //
    // CLUT
    //

    reg  [CIDX_ADDRW-1:0] clut_addr_disp;
    wire [COLRW-1:0] clut_dout_disp;

    clut #(
        .ADDRW(CIDX_ADDRW),
        .DATAW(COLRW),
        .FILE_PAL(FILE_PAL)
    ) clut_inst (
        /* verilator lint_off PINCONNECTEMPTY */
        .clk_sys(),
        /* verilator lint_on PINCONNECTEMPTY */
        .clk_pix(clk_pix),
        /* verilator lint_off PINCONNECTEMPTY */
        .we_sys(),  // for future CPU use
        .addr_sys(),
        .din_sys(),
        .dout_sys(),
        /* verilator lint_on PINCONNECTEMPTY */
        .addr_disp(clut_addr_disp),
        .dout_disp(clut_dout_disp)
    );


    //
    // Display Controller
    //

    display #(
        .CORDW(CORDW),
        .MODE(DISPLAY_MODE)
    ) display_inst (
        .clk_pix(clk_pix),
        .rst_pix(rst_pix),
        /* verilator lint_off PINCONNECTEMPTY */
        .hres(),
        .vres(),
        /* verilator lint_on PINCONNECTEMPTY */
        .dx(dx),
        .dy(dy),
        .hsync(hsync),
        .vsync(vsync),
        .de(de),
        .frame_start(frame_start),
        .line_start(line_start)
    );

    // frame_start in system clock domain
    xd xd_frame_start (
        .clk_src(clk_pix),
        .clk_dst(clk_sys),
        .flag_src(frame_start),
        .flag_dst(frame_start_sys)
    );


    //
    // Painting & Display Output
    //

    assign vram_addr_disp = disp_addr;

    // CLUT lookup takes two cycles; delay disp_pix_id to match
    reg [PIX_IDW-1:0] pix_id_p1, pix_id_p2;
    always @(posedge clk_pix) begin
        pix_id_p1 <= disp_pix_id;
        pix_id_p2 <= pix_id_p1;
    end

    // select pixel ID from word depending on colour depth
    reg [CIDX_ADDRW-1:0] pcidx_1, pcidx_2, pcidx_4, pcidx_8;
    always @(*) begin
        /* verilator lint_off WIDTHTRUNC */
        pcidx_1 = (vram_dout_disp >> pix_id_p2)        & 'b1;
        pcidx_2 = (vram_dout_disp >> (pix_id_p2 << 1)) & 'b11;
        pcidx_4 = (vram_dout_disp >> (pix_id_p2 << 2)) & 'b1111;
        pcidx_8 = (vram_dout_disp >> (pix_id_p2 << 3)) & 'b11111111;
        /* verilator lint_on WIDTHTRUNC */
        case (CANV_BPP)
            1: clut_addr_disp = pcidx_1;
            2: clut_addr_disp = pcidx_2;
            4: clut_addr_disp = pcidx_4;
            8: clut_addr_disp = pcidx_8;
            default: clut_addr_disp = pcidx_4;
        endcase
    end

    reg [BPC-1:0] paint_r, paint_g, paint_b;
    always @(*) {paint_r, paint_g, paint_b} = canv_paint ? clut_dout_disp : BG_COLR;

    // register display signals
    always @(posedge clk_pix) begin
        disp_x <= dx;
        disp_y <= dy;
        disp_hsync <= hsync;
        disp_vsync <= vsync;
        disp_de <= de;
        disp_frame <= frame_start;
        disp_r <= (de) ? paint_r : 'h0;  // paint colour but black in blanking
        disp_g <= (de) ? paint_g : 'h0;
        disp_b <= (de) ? paint_b : 'h0;
    end
endmodule
