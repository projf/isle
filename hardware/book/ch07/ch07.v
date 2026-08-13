// Isle.Computer - Chapter 7: Graphics Devices
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

`default_nettype none
`timescale 1ns / 1ps

module ch07 #(
    parameter BPC=5,              // bits per colour channel
    parameter CORDW=16,           // signed coordinate width (bits)
    parameter DISPLAY_MODE=0,     // display mode (see display_modes.vh)
    parameter FILE_BMAP="",       // initial bitmap file for vram
    parameter FILE_ER_LIST="",    // initial command list for Earthrise
    parameter FILE_FONT="",       // font glyph ROM file
    parameter FILE_PAL="",        // initial palette for CLUT
    parameter FILE_SOFT="",       // initial software in system ram
    parameter FILE_TXT="",        // initial text file for tram
    parameter FONT_COUNT=128,     // number of glyphs in font ROM
    parameter GLYPH_HEIGHT=16,    // font glyph height (pixels)
    parameter GLYPH_WIDTH=8,      // font half-width glyph width (pixels)
    parameter TIMER_DIV=20000,    // millisecond divider
    parameter UART_CNT_INC=6036,  // 16 x baud counter increment
    parameter UART_CNT_W=16       // 16 x baud counter width (bits)
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
    output reg  [BPC-1:0] disp_b,           // blue display channel
    input  wire uart_rx,                    // UART receive to Isle
    output wire uart_tx                     // UART transmit from Isle
    );

    // CPU, bus, sysram
    localparam CPU_RESET_ADDR = 'h80_0000;  // must match linker script
    localparam BUSW = 22;  // bus address width (words) - 2^22 × 4 bytes = 16M
    localparam SYSRAM_ADDRW = 12;  // sysram word width - 2^12 words = 16K
    localparam STACK_ADDRW  = 10;  // stack word width - 2^10 words = 4K (0xFF_F000)

    // vram - 16K x 32-bit (64 KiB) with bit write
    //   NB. Due to bit write, minimum depth is 64 KiB with 18 Kb bram
    localparam VRAM_ADDRW = 14;  // vram address width (bits)
    localparam VRAM_LAT   =  2;  // vram display read latency (cycles, min=1)

    // Earthrise
    localparam ER_ADDRW = 10;     // 2^10 = 1024 x 32-bit = 4 KiB (word addressed)

    // text mode
    localparam TEXT_CIDXW =  4;  // 16 colours available in textmode
    localparam TRAM_ADDRW = 11;  // tram address width (bits)
    localparam TRAM_HRES  = 16'd84;  // tram width (chars) - 84x8 = 672
    localparam TRAM_VRES  = 16'd24;  // tram height (chars) - 24x16 = 384
    localparam TRAM_LAT   =  2;  // tram display read latency (cycles, min=1, max=2)

    // uart
    localparam UART_DATAW = 8;  // uart data width (bits)
    localparam UART_FIFO_RX_ADDRW = 4;  // RX fifo address width (bits)

    // internal system params
    localparam BYTE =  8;  // machine byte size (bits)
    localparam WORD = 32;  // machine word size (bits)
    localparam BYTE_CNT = WORD / BYTE;  // bytes in word (for write enable)
    localparam CANV_SHIFTW = 3;  // max shift is 5 bits (2^5 = 32 bits)
    localparam CIDX_ADDRW  = 8;  // colour index address width 2^8 = 256 colours
    localparam CLUT_LAT    = 2;  // clut display read latency (cycles, min=1)
    localparam COLRW = 3 * BPC;  // colour width across three channels (bits)
    localparam DEV_ADDRW  = 14;  // device word address width 14 = 64 KiB


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
        .ADDRW(WORD),  // word address width; otherwise we can't catch addresses outside memory map
        .RESET_ADDR(CPU_RESET_ADDR)
    ) cpu (
        .clk(clk_sys),
        .rst_n(!rst_sys),
        .mem_addr(cpu_addr),
        .mem_wdata(cpu_wdata),
        .mem_wmask(cpu_wmask),
        .mem_rdata(cpu_rdata),
        .mem_rstrb(cpu_rstrb),
        .mem_rbusy(cpu_rbusy),
        .mem_wbusy(cpu_wbusy),
        .irq(1'b0)  // no interrupts
    );


    //
    // Bus
    //

    // link CPU to bus
    wire [BUSW-1:0] io_addr = cpu_addr[BUSW+1:2];  // IO bus is word addressed
    wire [BYTE_CNT-1:0] io_wstrb = cpu_wmask;
    wire [WORD-1:0] io_wdata = cpu_wdata;
    wire io_rstrb = cpu_rstrb;

    // memory region base addresses
    localparam STACK_BASE  = 'hFF_F000 >> 2;  // shift as word addressed
    localparam SYSRAM_BASE = 'h80_0000 >> 2;
    localparam TRAM_BASE   = 'h50_0000 >> 2;
    localparam CLUT_BASE   = 'h58_0000 >> 2;

    // address decoding for chip select signal - no aliasing because of comparison with BASE addr
    wire stack_cs  = (io_addr[BUSW-1:STACK_ADDRW] == STACK_BASE[BUSW-1:STACK_ADDRW]);
    wire sysram_cs = (io_addr[BUSW-1:SYSRAM_ADDRW] == SYSRAM_BASE[BUSW-1:SYSRAM_ADDRW]);
    wire tram_cs   = (io_addr[BUSW-1:TRAM_ADDRW] == TRAM_BASE[BUSW-1:TRAM_ADDRW]);
    wire clut_cs   = (io_addr[BUSW-1:CIDX_ADDRW] == CLUT_BASE[BUSW-1:CIDX_ADDRW]);

    // devices (temporarily using fixed slots; can we remove magic number to base addresses?)
    wire dev_cs      = (io_addr[BUSW-1:BUSW-4] == 'b0110);   // 0x6 ('b0110)
    wire sys_dev_cs  = dev_cs & (io_addr[BUSW-5:BUSW-8] == 'h0);
    wire disp_dev_cs = dev_cs & (io_addr[BUSW-5:BUSW-8] == 'h1);
    wire uart_dev_cs = dev_cs & (io_addr[BUSW-5:BUSW-8] == 'h2);
    wire er_dev_cs   = dev_cs & (io_addr[BUSW-5:BUSW-8] == 'h3);

    // Write I/O busy
    wire disp_dev_wbusy;  // display hwreg can be busy, so CPU might need to wait
    wire io_wbusy = disp_dev_wbusy;  // will have other devices later

    // Read I/O busy
    reg io_rbusy;
    wire uart_dev_rbusy;
    always @(*) begin
        case(1'b1)
            uart_dev_cs: io_rbusy = uart_dev_rbusy;
            default: io_rbusy = 0;
        endcase
    end

    // read data
    reg  [WORD-1:0] io_rdata;
    wire [WORD-1:0] sysram_dout;
    wire [WORD-1:0] stack_dout;
    wire [WORD-1:0] tram_dout_sys;
    wire [COLRW-1:0] clut_dout_sys;
    wire [WORD-1:0] sys_dev_dout;
    wire [WORD-1:0] disp_dev_dout;
    wire [WORD-1:0] uart_dev_dout;
    wire [WORD-1:0] er_dev_dout;

    // doesn't yet capture bus faults within devices
    reg mapped_addr;
    always @(*) begin
        mapped_addr = 1;
        case(1'b1)
            sysram_cs:   io_rdata = sysram_dout;
            stack_cs:    io_rdata = stack_dout;
            tram_cs:     io_rdata = tram_dout_sys;
            clut_cs:     io_rdata = {{WORD-COLRW{1'b0}}, clut_dout_sys};
            sys_dev_cs:  io_rdata = sys_dev_dout;
            disp_dev_cs: io_rdata = disp_dev_dout;
            uart_dev_cs: io_rdata = uart_dev_dout;
            er_dev_cs:   io_rdata = er_dev_dout;
            default: begin
                io_rdata = 0;
                mapped_addr = 0;  // unmapped address
            end
        endcase
    end
    assign cpu_rdata = io_rdata;  // CPU reads from selected memory range

    // bus fault if we attempt to access bus with unmapped address
    wire addr_in_map = ~|cpu_addr[WORD-1:BUSW+2];  // 24-bit addr space; upper 8 bits must be zero
    wire bus_access = io_rstrb | (|io_wstrb);
    wire bus_fault = bus_access & (~mapped_addr | ~addr_in_map);

    // permanently stall on bus fault (we don't have interrupts yet)
    reg bus_stall;
    always @(posedge clk_sys) begin
        if (rst_sys)        bus_stall <= 0;
        else if (bus_fault) bus_stall <= 1;
    end

    // CPU waits if IO is busy or (indefinitely) if bus is stalled
    assign cpu_wbusy = io_wbusy | bus_stall;
    assign cpu_rbusy = io_rbusy | bus_stall;

    // we don't yet have interrupts, so display bus fault (byte address) in sim
    always @(posedge clk_sys) begin
        if (bus_fault && !bus_stall) begin
            $display("** BUS FAULT at address 0x%h **", cpu_addr);
        end
    end


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
    // Stack
    //

    sysram #(
        .BYTE(BYTE),
        .BYTE_CNT(BYTE_CNT),
        .WORD(WORD),
        .ADDRW(STACK_ADDRW),
        .FILE_SOFT("")
    ) stack_inst (
        .clk(clk_sys),
        .we(io_wstrb & {BYTE_CNT{stack_cs}}),
        .re(io_rstrb & stack_cs),
        .addr(io_addr[STACK_ADDRW-1:0]),
        .din(io_wdata),
        .dout(stack_dout)
    );


    //
    // Video RAM (vram) - TODO: Add CPU vram access (multiplex with Earthrise)
    //

    wire [VRAM_ADDRW-1:0] vram_addr_sys;
    wire [WORD-1:0] vram_wmask_sys;
    wire vram_re_sys = 0;  // will be used when we add CPU access
    wire [WORD-1:0] vram_din_sys;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [WORD-1:0] vram_dout_sys;  // will be used when we add CPU access
    /* verilator lint_on UNUSEDSIGNAL */
    wire [VRAM_ADDRW-1:0] vram_addr_disp;  // pixel clock domain
    wire [WORD-1:0] vram_dout_disp;  // pixel clock domain

    // Earthrise vram signals
    wire [VRAM_ADDRW-1:0] er_vram_addr;
    wire [WORD-1:0] er_vram_din;
    wire [WORD-1:0] er_vram_wmask;

    // use Earthrise for system I/O (will multiplex with CPU later)
    assign vram_addr_sys = er_vram_addr;  // doesn't validate address, but vram depth is power of two
    assign vram_din_sys = er_vram_din;
    assign vram_wmask_sys = er_vram_wmask;

    // for CPU write to vram
    // wire [WORD-1:0] vram_wmask_sys = {{8{io_wstrb[3]}}, {8{io_wstrb[2]}}, {8{io_wstrb[1]}}, {8{io_wstrb[0]}}};

    vram #(
        .WORD(WORD),
        .ADDRW(VRAM_ADDRW),
        .FILE_BMAP(FILE_BMAP)
        ) vram_inst (
        .clk_sys(clk_sys),
        .clk_pix(clk_pix),
        .wmask_sys(vram_wmask_sys),
        .re_sys(vram_re_sys),
        .addr_sys(vram_addr_sys),
        .din_sys(vram_din_sys),
        .dout_sys(vram_dout_sys),
        .addr_disp(vram_addr_disp),
        .dout_disp(vram_dout_disp)
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
    // System Device
    //

    dev_sys #(
        .DEV_ADDRW(DEV_ADDRW),
        .TIMER_DIV(TIMER_DIV),
        .WORD(WORD)
    ) dev_sys_inst (
        .clk(clk_sys),
        .rst(rst_sys),
        .we(|io_wstrb & sys_dev_cs),
        .re(io_rstrb & sys_dev_cs),
        .addr(io_addr[DEV_ADDRW-1:0]),
        .din(io_wdata),
        .dout(sys_dev_dout)
    );


    //
    // Display Device
    //

    wire signed [CORDW-1:0] dx, dy;  // display position
    wire hsync, vsync;  // display sync
    wire de;  // display data enable
    wire frame_start;  // high for one cycle at frame start
    wire [BPC-1:0] paint_r, paint_g, paint_b;  // paint colours

    dev_display #(
        .BPC(BPC),
        .BYTE_CNT(BYTE_CNT),
        .CANV_SHIFTW(CANV_SHIFTW),
        .CIDX_ADDRW(CIDX_ADDRW),
        .CLUT_LAT(CLUT_LAT),
        .COLRW(COLRW),
        .CORDW(CORDW),
        .DEV_ADDRW(DEV_ADDRW),
        .DISPLAY_MODE(DISPLAY_MODE),
        .TRAM_ADDRW(TRAM_ADDRW),
        .TRAM_HRES(TRAM_HRES),
        .TRAM_VRES(TRAM_VRES),
        .TRAM_LAT(TRAM_LAT),
        .VRAM_ADDRW(VRAM_ADDRW),
        .VRAM_LAT(VRAM_LAT),
        .WORD(WORD),
        .FILE_FONT(FILE_FONT),
        .FONT_COUNT(FONT_COUNT),
        .GLYPH_HEIGHT(GLYPH_HEIGHT),
        .GLYPH_WIDTH(GLYPH_WIDTH),
        .TEXT_CIDXW(TEXT_CIDXW)
    ) dev_display_inst (
        .clk_sys(clk_sys),
        .clk_pix(clk_pix),
        .rst_sys(rst_sys),
        .rst_pix(rst_pix),
        .we_sys(io_wstrb & {BYTE_CNT{disp_dev_cs}}),
        .re_sys(io_rstrb & disp_dev_cs),
        .addr_sys(io_addr[DEV_ADDRW-1:0]),
        .din_sys(io_wdata),
        .dout_sys(disp_dev_dout),
        .wbusy(disp_dev_wbusy),
        .clut_addr(clut_addr_disp),
        .clut_dout(clut_dout_disp),
        .tram_addr(tram_addr_disp),
        .tram_dout(tram_dout_disp),
        .vram_addr(vram_addr_disp),
        .vram_dout(vram_dout_disp),
        .dx(dx),
        .dy(dy),
        .hsync(hsync),
        .vsync(vsync),
        .de(de),
        .frame_start(frame_start),
        .r(paint_r),
        .g(paint_g),
        .b(paint_b)
    );


    //
    // UART Device
    //

    dev_uart #(
        .DEV_ADDRW(DEV_ADDRW),
        .UART_CNT_INC(UART_CNT_INC),
        .UART_CNT_W(UART_CNT_W),
        .UART_DATAW(UART_DATAW),
        .UART_FIFO_RX_ADDRW(UART_FIFO_RX_ADDRW),
        .WORD(WORD)
    ) dev_uart_inst (
        .clk(clk_sys),
        .rst(rst_sys),
        .we(|io_wstrb & uart_dev_cs),
        .re(io_rstrb & uart_dev_cs),
        .addr(io_addr[DEV_ADDRW-1:0]),
        .din(io_wdata),
        .dout(uart_dev_dout),
        .rbusy(uart_dev_rbusy),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );


    //
    // Earthrise Device
    //

    dev_earthrise #(
        .BYTE(BYTE),
        .BYTE_CNT(BYTE_CNT),
        .CANV_SHIFTW(CANV_SHIFTW),
        .CORDW(CORDW),
        .DEV_ADDRW(DEV_ADDRW),
        .ER_ADDRW(ER_ADDRW),
        .ER_COLRW(CIDX_ADDRW),
        .FILE_ER_LIST(FILE_ER_LIST),
        .VRAM_ADDRW(VRAM_ADDRW),
        .WORD(WORD)
    ) dev_earthrise_inst (
        .clk(clk_sys),
        .rst(rst_sys),
        .en(1'b1),  // needed for future vram multiplexing
        .we(io_wstrb & {4{er_dev_cs}}),  // byte write for command list only
        .re(io_rstrb & er_dev_cs),
        .addr(io_addr[DEV_ADDRW-1:0]),
        .din(io_wdata),
        .dout(er_dev_dout),
        .vram_addr(er_vram_addr),
        .vram_din(er_vram_din),
        .vram_wmask(er_vram_wmask)
    );


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
