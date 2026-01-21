// Isle.Computer - Chapter 5: RISC-V CPU
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module ch05 #(
    parameter BPC=5,             // bits per colour channel
    parameter BG_COLR='h0886,    // background colour (RGB555)
    parameter CORDW=16,          // signed coordinate width (bits)
    parameter DISPLAY_MODE=0,    // display mode (see display.v for modes)
    parameter FILE_FONT="",      // font glyph ROM file
    parameter FILE_PAL="",       // initial palette for CLUT
    parameter FILE_SOFT="",      // initial software in system ram
    parameter FILE_TXT="",       // initial text file for tram
    parameter FONT_COUNT=128,    // number of glyphs in font ROM
    parameter GLYPH_HEIGHT=16,   // font glyph height (pixels)
    parameter GLYPH_WIDTH=8,     // font half-width glyph width (pixels)
    parameter TEXT_SCALE=32'h0,  // text mode scale hYYYYXXXX
    parameter WIN_END=32'h0,     // text window end coords 'hYYYYXXXX
    parameter WIN_START=32'h0    // text window start coords 'hYYYYXXXX
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

    // CPU, bus, sysram
    localparam CPU_RESET_ADDR = 'h8000;  // must match linker script
    localparam BUSW = 14;  // bus address width (words) - 2^14 × 4 bytes = 64K
    localparam SYSRAM_ADDRW = 12;  // sysram word width - 2^12 words = 16K

    // text mode
    localparam TEXT_CIDXW =  4;  // 16 colours available in textmode
    localparam TRAM_ADDRW = 11;  // tram address width (bits)
    localparam TRAM_HRES  = 84;  // tram width (chars) - 84x8 = 672
    localparam TRAM_VRES  = 24;  // tram height (chars) - 24x16 = 384
    localparam [TRAM_ADDRW-1:0] TRAM_DEPTH = TRAM_HRES * TRAM_VRES;
    localparam TRAM_LAT   =  1;  // tram read latency (cycles)

    // internal system params
    localparam WORD = 32;  // machine word size (bits)
    localparam BYTE =  8;  // machine byte size (bits)
    localparam BYTE_CNT = WORD / BYTE;  // bytes in word (for write enable)
    localparam CIDX_ADDRW = 8;   // colour index address width 2^8 = 256 colours
    localparam COLRW = 3 * BPC;  // colour width across three channels (bits)
    localparam CLUT_LAT =   2;   // CLUT read latency (cycles)

    // display signals
    wire signed [CORDW-1:0] dx, dy;
    wire hsync, vsync, de;
    wire frame_start;
    wire frame_start_sys;  // frame start in system clock domain

    // CPU signals
    /* verilator lint_off UNUSEDSIGNAL */
    wire [WORD-1:0] cpu_addr;  // external address is always word width
    /* verilator lint_on UNUSEDSIGNAL */
    wire [WORD-1:0] cpu_wdata;
    wire [BYTE_CNT-1:0] cpu_wmask;
    wire [WORD-1:0] cpu_rdata;
    wire cpu_rstrb;
    wire cpu_rbusy;
    wire cpu_wbusy;


    //
    // RISC-V CPU
    //

    FemtoRV32 #(
        .ADDR_WIDTH(BUSW+2),  // +2 for byte addressing
        .RESET_ADDR(CPU_RESET_ADDR)
    ) cpu (
        .clk(clk_sys),
        .mem_addr(cpu_addr),
        .mem_wdata(cpu_wdata),
        .mem_wmask(cpu_wmask),
        .mem_rdata(cpu_rdata),
        .mem_rstrb(cpu_rstrb),
        .mem_rbusy(cpu_rbusy),
        .mem_wbusy(cpu_wbusy),
        .reset(!rst_sys)  // reset low
    );


    //
    // Bus
    //

    wire [BUSW-1:0] io_addr = cpu_addr[BUSW+1:2];  // IO bus is word addressed
    wire [BYTE_CNT-1:0] io_wstrb = cpu_wmask;
    wire [WORD-1:0] io_wdata = cpu_wdata;
    wire io_rstrb = cpu_rstrb;

    // address decoding for chip select signals
    wire sysram_cs = (io_addr[BUSW-1:BUSW-2] == 'b10);
    wire tram_cs   = (io_addr[BUSW-1:BUSW-2] == 'b01);
    wire clut_cs   = (io_addr[BUSW-1:BUSW-2] == 'b00);
    wire hwreg_cs  = (io_addr[BUSW-1:BUSW-2] == 'b11);

    // CPU IO busy - not required in this design
    assign cpu_wbusy = 0;
    assign cpu_rbusy = 0;

    // read data
    reg  [WORD-1:0] io_rdata;
    wire [WORD-1:0] sysram_dout;
    wire [WORD-1:0] tram_dout_sys;
    wire [COLRW-1:0] clut_dout_sys;
    reg  [WORD-1:0] hwreg_dout;  // reg as not separate module
    always @(*) begin
        case(1'b1)
            sysram_cs: io_rdata = sysram_dout;
            tram_cs:   io_rdata = tram_dout_sys;
            clut_cs:   io_rdata = {{WORD-COLRW{1'b0}}, clut_dout_sys};
            hwreg_cs:  io_rdata = hwreg_dout;
            default:   io_rdata = 0;
        endcase
    end
    assign cpu_rdata = io_rdata;


    //
    // System RAM (sysram)
    //

    sysram #(
        .BYTE(BYTE),
        .BYTE_CNT(BYTE_CNT),
        .WORD(WORD),
        .ADDRW(SYSRAM_ADDRW),
        .FILE_SOFT(FILE_SOFT)
    ) sysram_inst (
        .clk(clk_sys),
        .we(io_wstrb & {BYTE_CNT{sysram_cs}}),
        .re(io_rstrb & sysram_cs),
        .addr(io_addr[SYSRAM_ADDRW-1:0]),
        .din(io_wdata),
        .dout(sysram_dout)
    );


    //
    // Text Mode RAM (tram)
    //

    wire [TRAM_ADDRW-1:0] tram_addr_disp;
    wire [WORD-1:0] tram_dout_disp;

    tram #(
        .BYTE(BYTE),
        .BYTE_CNT(BYTE_CNT),
        .WORD(WORD),
        .ADDRW(TRAM_ADDRW),
        .FILE_TXT(FILE_TXT)
    ) tram_inst (
        .clk_sys(clk_sys),
        .clk_pix(clk_pix),
        .we_sys(io_wstrb & {BYTE_CNT{tram_cs}}),
        .re_sys(io_rstrb & tram_cs),
        .addr_sys(io_addr[TRAM_ADDRW-1:0]),
        .din_sys(io_wdata),
        .dout_sys(tram_dout_sys),
        .addr_disp(tram_addr_disp),
        .dout_disp(tram_dout_disp)
    );


    //
    // Text Mode
    //

    // fixed tram size for now; CPU will control through hardware registers
    reg signed [TRAM_ADDRW-1:0] text_hres = TRAM_HRES;
    reg signed [TRAM_ADDRW-1:0] text_vres = TRAM_VRES;

    reg [TRAM_ADDRW-1:0] scroll_offs = 0*84;  // scroll text display (use lines of chars)
    wire [TEXT_CIDXW-1:0] text_pix;
    wire paint_text;  // signals when to enable text painting

    textmode #(
        .CORDW(CORDW),
        .WORD(WORD),
        .ADDRW(TRAM_ADDRW),
        .CIDXW(TEXT_CIDXW),
        .CLUT_LAT(CLUT_LAT),
        .FILE_FONT(FILE_FONT),
        .FONT_COUNT(FONT_COUNT),
        .GLYPH_HEIGHT(GLYPH_HEIGHT),
        .GLYPH_WIDTH(GLYPH_WIDTH),
        .TRAM_DEPTH(TRAM_DEPTH),
        .TRAM_LAT(TRAM_LAT)
    ) textmode_inst (
        .clk_pix(clk_pix),
        .rst_pix(rst_pix),
        .frame_start(frame_start),
        .dx(dx),
        .dy(dy),
        .scroll_offs(scroll_offs),
        .text_hres(text_hres),
        .text_vres(text_vres),
        .win_start(WIN_START),
        .win_end(WIN_END),
        .scale(TEXT_SCALE),
        .tram_data(tram_dout_disp),
        .tram_addr(tram_addr_disp),
        .pix(text_pix),
        .paint(paint_text)
    );


    //
    // CLUT
    //

    wire [CIDX_ADDRW-1:0] clut_addr_disp;
    wire [COLRW-1:0] clut_dout_disp;

    clut #(
        .ADDRW(CIDX_ADDRW),
        .DATAW(COLRW),
        .FILE_PAL(FILE_PAL)
    ) clut_inst (
        .clk_sys(clk_sys),
        .clk_pix(clk_pix),
        .we_sys(&io_wstrb & clut_cs),  // word write only (reduction AND)
        .re_sys(io_rstrb & clut_cs),
        .addr_sys(io_addr[CIDX_ADDRW-1:0]),
        .din_sys(io_wdata[COLRW-1:0]),
        .dout_sys(clut_dout_sys),
        .addr_disp(clut_addr_disp),
        .dout_disp(clut_dout_disp)
    );


    //
    // Hardware Registers
    //

    // must match software
    /* verilator lint_off WIDTHTRUNC */
    localparam [BUSW-1:0] FRAME_FLAG = 'hC110 >> 2;  // word addressing
    localparam [BUSW-1:0] FRAME_FLAG_CLR = 'hC114 >> 2;
    /* verilator lint_on WIDTHTRUNC */

    // frame flag
    reg frame_flag, frame_flag_clr;

    // clear frame flag (strobe)
    always @(*) frame_flag_clr = (&io_wstrb && (io_addr == FRAME_FLAG_CLR));

    // update frame flag
    always @(posedge clk_sys) begin
        if (frame_start_sys) frame_flag <= 1;
        else if (frame_flag_clr) frame_flag <= 0;
        if (rst_sys) frame_flag <= 0;
    end

    always @(posedge clk_sys) begin
        if (io_rstrb & hwreg_cs) begin  // read hardware register
            if (io_addr == FRAME_FLAG) hwreg_dout <= {{WORD-1{1'b0}}, frame_flag};
        end
        if (rst_sys) hwreg_dout <= 0;
    end


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
        /* verilator lint_off PINCONNECTEMPTY */
        .line_start()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    xd xd_frame_start (
        .clk_src(clk_pix),
        .clk_dst(clk_sys),
        .flag_src(frame_start),
        .flag_dst(frame_start_sys)
    );


    //
    // Painting & Display Output
    //

    assign clut_addr_disp = {{CIDX_ADDRW-TEXT_CIDXW{1'b0}}, text_pix};

    reg [BPC-1:0] paint_r, paint_g, paint_b;
    always @(*) {paint_r, paint_g, paint_b} = paint_text ? clut_dout_disp : BG_COLR;

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
