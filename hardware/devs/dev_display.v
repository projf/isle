// Isle.Computer - Display Device
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module dev_display #(
    parameter BPC=5,             // bits per colour channel
    parameter BYTE_CNT=4,        // bytes in word
    parameter CANV_SHIFTW=3,     // max shift is 5 bits (2^5 = 32 bits)
    parameter CIDX_ADDRW=8,      // colour index address width (bits)
    parameter CLUT_LAT=2,        // clut display read latency (cycles, min=1)
    parameter COLRW=15,          // colour width across three channels (bits)
    parameter CORDW=16,          // signed coordinate width (bits)
    parameter DEV_ADDRW=14,      // device address width (bits)
    parameter DISPLAY_MODE=0,    // display mode (see display_modes.vh)
    parameter TRAM_ADDRW=11,     // tram address width (bits)
    parameter TRAM_HRES=16'd84,  // tram width (chars) - 84x8 = 672
    parameter TRAM_VRES=16'd24,  // tram height (chars) - 24x16 = 384
    parameter TRAM_LAT=2,        // tram display read latency (cycles, min=1, max 2)
    parameter VRAM_ADDRW=14,     // vram address width (bits)
    parameter VRAM_LAT=2,        // vram display read latency (cycles, min=1)
    parameter WORD=32,           // machine word size (bits)
    // text mode
    parameter FILE_FONT="",      // font glyph ROM file
    parameter FONT_COUNT=128,    // number of glyphs in font ROM
    parameter GLYPH_HEIGHT=16,   // font glyph height (pixels)
    parameter GLYPH_WIDTH=8,     // font half-width glyph width (pixels)
    parameter TEXT_CIDXW=4       // text mode colour index address width (bits)
    ) (
    input  wire clk_sys,  // system clock
    input  wire clk_pix,  // pixel clock
    input  wire rst_sys,  // reset (system clock domain)
    input  wire rst_pix,  // reset (pixel clock domain)

    // system (CPU) interface
    input  wire [BYTE_CNT-1:0] we_sys,  // system write enable
    input  wire re_sys,  // system read enable
    input  wire [DEV_ADDRW-1:0] addr_sys,  // address
    input  wire [WORD-1:0] din_sys,  // data in
    output reg  [WORD-1:0] dout_sys,  // data out
    output wire wbusy,  // device busy writing

    // clut/tram/vram
    output  reg [CIDX_ADDRW-1:0] clut_addr,
    input  wire [COLRW-1:0] clut_dout,
    output wire [TRAM_ADDRW-1:0] tram_addr,
    input  wire [WORD-1:0] tram_dout,
    output wire [VRAM_ADDRW-1:0] vram_addr,
    input  wire [WORD-1:0] vram_dout,

    // display output
    output wire signed [CORDW-1:0] dx, dy,  // display position
    output wire hsync, vsync,  // display sync
    output wire de,  // display data enable
    output wire frame_start,  // high for one cycle at frame start
    output reg  [BPC-1:0] r,g,b  // colour display channel
    );

    `include "display_modes.vh"

    // internal system params
    // copy hwreg into pixel clock domain, then start display of graphics/text
    localparam signed [CORDW-1:0] HWREG_COPY_LINE = -3;  // which display line to copy hwreg on
    localparam signed [CORDW-1:0] DISPLAY_START_LINE = HWREG_COPY_LINE + 1; // next line

    localparam PIX_IDXW=$clog2(WORD);  // pixel index width (bits)
    /* verilator lint_off WIDTHTRUNC */
    localparam [CORDW-1:0] TRAM_DEPTH = TRAM_HRES * TRAM_VRES;
    /* verilator lint_on WIDTHTRUNC */

    // initial params - to be nice to software devs
    localparam DISP_VISIBLE_INIT = 'h0303;  // text mode and canvas visibility inc. transparency
    localparam DISP_BG_COLR_INIT = 'h0886;  // display background colour RGB555
    localparam CANV_BPP_INIT = 4;  // canvas colour depth (4 bits = 16 colours)
    localparam CANV_DIMS_INIT = 'h00C00150;  // canvas dimensions h=192, w=336

    // HWREG_ADDR - must match software

    // read-only
    localparam [DEV_ADDRW-1:0] DISP_DIMS_RO   = 'h0100 >> 2;  // shift as word addressed
    localparam [DEV_ADDRW-1:0] BMAP_DIMS_RO   = 'h0104 >> 2;
    localparam [DEV_ADDRW-1:0] TEXT_DIMS_RO   = 'h0108 >> 2;
    localparam [DEV_ADDRW-1:0] FRAME_FLAG_RO  = 'h010C >> 2;
    localparam [DEV_ADDRW-1:0] FRAME_COUNT_RO = 'h0110 >> 2;
    localparam [DEV_ADDRW-1:0] TRAM_DEPTH_RO  = 'h0114 >> 2;

    // strobe
    localparam [DEV_ADDRW-1:0] FRAME_FLAG_CLR = 'h0180 >> 2;

    // read-write - offset from 0x200
    localparam RW_HWREG_CNT = 17;  // read-write hwreg count
    localparam RW_HWREG_W = $clog2(RW_HWREG_CNT);
    localparam RW_HWREG_BASE = 'h0200 >> 2;  // read-write reg base address

    localparam [RW_HWREG_W-1:0] DISP_VISIBLE = 0;
    localparam [RW_HWREG_W-1:0] DISP_BG_COLR = 1;

    localparam [RW_HWREG_W-1:0] TEXT_WIN_START = 2;
    localparam [RW_HWREG_W-1:0] TEXT_WIN_END = 3;
    localparam [RW_HWREG_W-1:0] TEXT_SCALE = 4;
    localparam [RW_HWREG_W-1:0] TEXT_PAL = 5;
    localparam [RW_HWREG_W-1:0] TEXT_TIDX = 6;
    localparam [RW_HWREG_W-1:0] TEXT_SCROLL_OFFSET = 7;

    localparam [RW_HWREG_W-1:0] CANV0_WIN_START = 8;
    localparam [RW_HWREG_W-1:0] CANV0_WIN_END = 9;
    localparam [RW_HWREG_W-1:0] CANV0_SCALE = 10;
    localparam [RW_HWREG_W-1:0] CANV0_PAL = 11;
    localparam [RW_HWREG_W-1:0] CANV0_TIDX = 12;
    localparam [RW_HWREG_W-1:0] CANV0_DIMS = 13;
    localparam [RW_HWREG_W-1:0] CANV0_VRAM_ADDR_BASE = 14;
    localparam [RW_HWREG_W-1:0] CANV0_BPP = 15;
    localparam [RW_HWREG_W-1:0] CANV0_SCROLL_COORD = 16;
    // don't forget to update RW_HWREG_CNT if you add registers

    // END_HWREG_ADDR

    // read-write hwreg
    reg [WORD-1:0] hwreg_sys [0:RW_HWREG_CNT-1];  // system clock domain
    reg [WORD-1:0] hwreg_pix [0:RW_HWREG_CNT-1];  // pixel clock domain


    //
    // Display Sync Signals and Coordinates
    //

    wire line_start;

    display_sync_gen #(
        .CORDW(CORDW),
        .DISPLAY_MODE(DISPLAY_MODE)
    ) display_sync_gen_inst (
        .clk_pix(clk_pix),
        .rst_pix(rst_pix),
        .dx(dx),
        .dy(dy),
        .hsync(hsync),
        .vsync(vsync),
        .de(de),
        .frame_start(frame_start),
        .line_start(line_start)
    );

    wire frame_start_sys;  // frame start in system clock domain
    xd xd_frame_start (
        .clk_src(clk_pix),
        .clk_dst(clk_sys),
        .flag_src(frame_start),
        .flag_dst(frame_start_sys)
    );

    //
    // Text Mode
    //

    wire [TEXT_CIDXW-1:0] text_pix;
    wire text_paint;  // signals when to enable text painting

    textmode #(
        .ADDRW(TRAM_ADDRW),
        .CIDXW(TEXT_CIDXW),
        .CLUT_LAT(CLUT_LAT),
        .CORDW(CORDW),
        .FILE_FONT(FILE_FONT),
        .FONT_COUNT(FONT_COUNT),
        .GLYPH_HEIGHT(GLYPH_HEIGHT),
        .GLYPH_WIDTH(GLYPH_WIDTH),
        .TRAM_DEPTH(TRAM_DEPTH[TRAM_ADDRW-1:0]),
        .TRAM_LAT(TRAM_LAT),
        .WORD(WORD)
    ) textmode_inst (
        .clk_pix(clk_pix),
        .rst_pix(rst_pix),
        .start(line_start && (dy == DISPLAY_START_LINE)),
        .dx(dx),
        .dy(dy),
        .win_start(hwreg_pix[TEXT_WIN_START]),
        .win_end(hwreg_pix[TEXT_WIN_END]),
        .scale(hwreg_pix[TEXT_SCALE]),
        .text_hres(TRAM_HRES[TRAM_ADDRW-1:0]),
        .text_vres(TRAM_VRES[TRAM_ADDRW-1:0]),
        .scroll_offset(hwreg_pix[TEXT_SCROLL_OFFSET][TRAM_ADDRW-1:0]),
        .tram_data(tram_dout),
        .tram_addr(tram_addr),
        .pix(text_pix),
        .paint(text_paint)
    );


    //
    // Canvas Display Address - will support additional canvas (canv1) in future
    //

    reg [CANV_SHIFTW-1:0] canv0_addr_shift;  // address shift based on canvas bits per pixel
    wire [VRAM_ADDRW-1:0] canv0_addr;  // pixel memory address
    wire [PIX_IDXW-1:0] canv0_pix_idx;  // pixel index within word
    wire canv0_paint;

    always @(*) begin
        case(hwreg_pix[CANV0_BPP])
            8: canv0_addr_shift = 2;
            4: canv0_addr_shift = 3;
            2: canv0_addr_shift = 4;
            1: canv0_addr_shift = 5;
            default: canv0_addr_shift = 3;
        endcase
    end

    canv_disp_agu #(
        .ADDRW(VRAM_ADDRW),
        .CLUT_LAT(CLUT_LAT),
        .CORDW(CORDW),
        .SHIFTW(CANV_SHIFTW),
        .VRAM_LAT(VRAM_LAT),
        .WORD(WORD)
    ) canv_disp_agu_inst (
        .clk_pix(clk_pix),
        .rst_pix(rst_pix),
        .start(line_start && (dy == DISPLAY_START_LINE)),
        .line_start(line_start),
        .dx(dx),
        .dy(dy),
        .win_start(hwreg_pix[CANV0_WIN_START]),
        .win_end(hwreg_pix[CANV0_WIN_END]),
        .scale(hwreg_pix[CANV0_SCALE]),
        .canv_dims(hwreg_pix[CANV0_DIMS]),
        .vram_addr_base(hwreg_pix[CANV0_VRAM_ADDR_BASE][VRAM_ADDRW-1:0]),
        .addr_shift(canv0_addr_shift),
        .scroll_coord(hwreg_pix[CANV0_SCROLL_COORD]),
        .vram_addr(canv0_addr),
        .pix_idx(canv0_pix_idx),
        .paint(canv0_paint)
    );


    //
    // generate colour output - combine text, bitmap, and background colours
    //
    assign vram_addr = canv0_addr;  // potential to support canv1 in later version

    reg [PIX_IDXW-1:0] pix_idx_pipe [0:VRAM_LAT-1];
    integer i;
    always @(posedge clk_pix) begin
        pix_idx_pipe[0] <= canv0_pix_idx;
        for (i=1; i<VRAM_LAT; i=i+1)
            pix_idx_pipe[i] <= pix_idx_pipe[i-1];
    end
    wire [PIX_IDXW-1:0] pix_idx_disp = pix_idx_pipe[VRAM_LAT-1];

    // select canvas pixel index from word depending on colour depth
    reg [CIDX_ADDRW-1:0] canv0_pix;
    reg [CIDX_ADDRW-1:0] pcidx_1, pcidx_2, pcidx_4, pcidx_8;
    always @(*) begin
        /* verilator lint_off WIDTHTRUNC */
        pcidx_1 = (vram_dout >> pix_idx_disp)        & 'b1;
        pcidx_2 = (vram_dout >> (pix_idx_disp << 1)) & 'b11;
        pcidx_4 = (vram_dout >> (pix_idx_disp << 2)) & 'b1111;
        pcidx_8 = (vram_dout >> (pix_idx_disp << 3)) & 'b11111111;
        /* verilator lint_on WIDTHTRUNC */
        case (hwreg_pix[CANV0_BPP])
            1: canv0_pix = pcidx_1;
            2: canv0_pix = pcidx_2;
            4: canv0_pix = pcidx_4;
            8: canv0_pix = pcidx_8;
            default: canv0_pix = pcidx_4;
        endcase
    end

    // visibility and transparency
    wire text_vi = hwreg_pix[DISP_VISIBLE][0] && text_paint;
    wire text_tr = hwreg_pix[DISP_VISIBLE][8] && text_pix == hwreg_pix[TEXT_TIDX][TEXT_CIDXW-1:0];
    wire canv0_vi = hwreg_pix[DISP_VISIBLE][1] && canv0_paint;
    wire canv0_tr = hwreg_pix[DISP_VISIBLE][9] && canv0_pix == hwreg_pix[CANV0_TIDX][CIDX_ADDRW-1:0];

    // paint colour - need to consider latency of transparency check vs clut
    reg bg_visible;  // background visible for latency correction
    always @(*) begin
        if (text_vi && !text_tr) begin
            clut_addr = hwreg_pix[TEXT_PAL][CIDX_ADDRW-1:0] + {{CIDX_ADDRW-TEXT_CIDXW{1'b0}}, text_pix};
            bg_visible = 0;
        end else if (canv0_vi && !canv0_tr) begin
            clut_addr = hwreg_pix[CANV0_PAL][CIDX_ADDRW-1:0] + canv0_pix;
            bg_visible = 0;
        end else begin  // display background
            clut_addr = 0;
            bg_visible = 1;
        end
    end

    reg [CLUT_LAT-1:0] bg_visible_pipe;
    /* verilator lint_off WIDTHEXPAND */
    always @(posedge clk_pix) bg_visible_pipe <= (bg_visible_pipe << 1) | bg_visible;
    /* verilator lint_on WIDTHEXPAND */

    // paint colours (registered in root module)
    wire [COLRW-1:0] bg_colr = hwreg_pix[DISP_BG_COLR][COLRW-1:0];
    always @(*) {r, g, b} = bg_visible_pipe[CLUT_LAT-1] ? bg_colr : clut_dout;


    //
    // hardware register logic
    //

    // frame flag and counter
    reg frame_flag;
    reg [WORD-1:0] frame_count;
    wire frame_flag_clr = (&we_sys && (addr_sys == FRAME_FLAG_CLR));  // requires *word* write
    always @(posedge clk_sys) begin  // update frame flag and counter
        if (frame_start_sys) begin  // set wins over clear
            frame_flag <= 1;
            frame_count <= frame_count + 1;
        end else if (frame_flag_clr) frame_flag <= 0;
        if (rst_sys) begin
            frame_flag <= 0;
            frame_count <= 0;
        end
    end

    /* verilator lint_off WIDTHTRUNC */
    wire hwreg_valid = (addr_sys >= RW_HWREG_BASE) &&
                       (addr_sys < RW_HWREG_BASE + RW_HWREG_CNT);
    wire [RW_HWREG_W-1:0] hwreg_idx = addr_sys - RW_HWREG_BASE;
    /* verilator lint_on WIDTHTRUNC */

    // hardware registers are marked busy for one line per frame
    reg hwreg_busy_pix;
    always @(posedge clk_pix) begin
        if (rst_pix) hwreg_busy_pix <= 0;
        else if (line_start) hwreg_busy_pix <= (dy == HWREG_COPY_LINE) ? 1 : 0;
    end

    // make hwreg busy status available in system clock domain
    (* ASYNC_REG = "TRUE" *) reg [1:0] hwreg_busy_sync;
    always @(posedge clk_sys) begin
        if (rst_sys) hwreg_busy_sync <= 0;
        else hwreg_busy_sync <= {hwreg_busy_sync[0], hwreg_busy_pix};
    end
    wire hwreg_busy_sys = hwreg_busy_sync[1];

    // copy registers into pixel clock domain once per frame
    integer j;
    always @(posedge clk_pix) begin
        if (hwreg_busy_pix && dx == 0) begin  // safe: CPU hasn't written for a while
            for (j = 0; j < RW_HWREG_CNT; j = j + 1)
                hwreg_pix[j] <= hwreg_sys[j];
        end
    end

    // CPU write to hwreg - handling writes when hwreg are busy being copied
    reg cpu_hwreg_write_pending;
    reg [RW_HWREG_W-1:0] hwreg_idx_pending;
    reg [WORD-1:0] din_sys_pending;
    always @(posedge clk_sys) begin
        if (rst_sys) begin  // set reasonable defaults to be nice to software devs
            cpu_hwreg_write_pending <= 0;
            hwreg_sys[DISP_VISIBLE] <= DISP_VISIBLE_INIT;
            hwreg_sys[DISP_BG_COLR] <= DISP_BG_COLR_INIT;
            hwreg_sys[TEXT_WIN_START] <= WIN_START_CORD;
            hwreg_sys[TEXT_WIN_END] <= WIN_END_CORD;
            hwreg_sys[TEXT_SCALE] <= DISPLAY_SCALE;
            hwreg_sys[CANV0_WIN_START] <= WIN_START_CORD;
            hwreg_sys[CANV0_WIN_END] <= WIN_END_CORD;
            hwreg_sys[CANV0_SCALE] <= DISPLAY_SCALE << 1;  // double for 336x192 canvas
            hwreg_sys[CANV0_DIMS] <= CANV_DIMS_INIT;
            hwreg_sys[CANV0_BPP] <= CANV_BPP_INIT;
        end else if ((&we_sys) && hwreg_valid && hwreg_busy_sys) begin  // word write (sw instruction)
            cpu_hwreg_write_pending <= 1;  // CPU write attempt when hwreg are busy
            hwreg_idx_pending <= hwreg_idx;  // capture write for when we need it
            din_sys_pending <= din_sys;
        end else if (cpu_hwreg_write_pending && !hwreg_busy_sys) begin
            hwreg_sys[hwreg_idx_pending] <= din_sys_pending;  // pending write made
            cpu_hwreg_write_pending <= 0;
        end else if ((&we_sys) && hwreg_valid && !hwreg_busy_sys) begin
            hwreg_sys[hwreg_idx] <= din_sys;  // write can be made immediately
        end
    end

    // CPU read hwreg
    always @(posedge clk_sys) begin
        if (re_sys) begin
            case (addr_sys)
                DISP_DIMS_RO:   dout_sys <= {VRES, HRES};
                BMAP_DIMS_RO:   dout_sys <= {BMAP_VRES, BMAP_HRES};
                TEXT_DIMS_RO:   dout_sys <= {TRAM_VRES, TRAM_HRES};
                FRAME_FLAG_RO:  dout_sys <= {{WORD-1{1'b0}}, frame_flag};
                FRAME_COUNT_RO: dout_sys <= frame_count;
                TRAM_DEPTH_RO:  dout_sys <= {{WORD-CORDW{1'b0}}, TRAM_DEPTH};
                default: dout_sys <= (hwreg_valid) ? hwreg_sys[hwreg_idx] : {WORD{1'b0}};
            endcase
        end
        if (rst_sys) dout_sys <= 0;
    end

    // wbusy needs to be asserted combinationally
    assign wbusy = cpu_hwreg_write_pending || ((&we_sys) && hwreg_valid && hwreg_busy_sys);
endmodule
