// Isle.Computer - Earthrise Device
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// TODO - use rbusy to handle extra cycle of latency on erlist read

`default_nettype none
`timescale 1ns / 1ps

module dev_earthrise #(
    parameter BYTE=8,           // machine byte size (bits)
    parameter BYTE_CNT=4,       // bytes in machine word
    parameter CANV_SHIFTW=3,    // max shift is 5 bits (2^5 = 32 bits)
    parameter CORDW=16,         // signed coordinate width (bits)
    parameter DEV_ADDRW=14,     // device address width (bits)
    parameter ER_ADDRW=10,      // command list address width
    parameter ER_COLRW=8,       // colour/pattern width (bits)
    parameter FILE_ER_LIST="",  // initial command list for Earthrise
    parameter VRAM_ADDRW=14,    // vram address width (bits)
    parameter WORD=32           // machine word size (bits)
    ) (
    input  wire clk,  // clock
    input  wire rst,  // reset
    input  wire en,   // enable (allows Earthrise to share vram bus)

    // system (CPU) interface
    input  wire [BYTE_CNT-1:0] we,  // system write enable
    input  wire re,  // system read enable
    input  wire [DEV_ADDRW-1:0] addr,  // address
    input  wire [WORD-1:0] din,   // data in
    output reg  [WORD-1:0] dout,  // data out
    output wire rbusy,  // device busy reading

    // vram interface
    output wire [VRAM_ADDRW-1:0] vram_addr,  // vram word address
    output reg  [WORD-1:0] vram_din,         // vram data in
    output reg  [WORD-1:0] vram_wmask        // vram write mask
    );

    localparam ER_DRAW_RATE = 1;  // slow Earthrise draw rate by this factor (1 for full speed)
    localparam PIX_IDXW=$clog2(WORD);  // pixel index width (bits)
    localparam ERLIST_BASE = 'h8000 >> 2;  // shift as word addressed

    // initial params - to be nice to software devs
    localparam ER_BPP_INIT = 4;  // canvas colour depth (4 bits = 16 colours)
    localparam ER_CANV_DIMS_INIT = 'h00C00150;  // canvas dimensions h=192, w=336

    // HWREG_ADDR - must match software
    /* verilator lint_off UNUSEDPARAM */
    localparam [DEV_ADDRW-1:0] ER_START_SB         = 'h0100 >> 2;  // shift as word addressed
    localparam [DEV_ADDRW-1:0] ER_RESET_SB         = 'h0104 >> 2;
    localparam [DEV_ADDRW-1:0] ER_BUSY_RO          = 'h0108 >> 2;
    localparam [DEV_ADDRW-1:0] ER_CYCLE_COUNT_RO   = 'h010C >> 2;
    localparam [DEV_ADDRW-1:0] ER_PC_RO            = 'h0110 >> 2;
    localparam [DEV_ADDRW-1:0] ER_INSTR_INVALID_RO = 'h0114 >> 2;

    localparam [DEV_ADDRW-1:0] ER_BPP              = 'h0200 >> 2;
    localparam [DEV_ADDRW-1:0] ER_CANV_DIMS        = 'h0204 >> 2;
    localparam [DEV_ADDRW-1:0] ER_VRAM_ADDR_BASE   = 'h0208 >> 2;
    /* verilator lint_on UNUSEDPARAM */
    // END_HWREG_ADDR

    // Earthrise Command List signals
    wire erlist_cs = (addr[DEV_ADDRW-1:ER_ADDRW] == ERLIST_BASE[DEV_ADDRW-1:ER_ADDRW]);
    wire [WORD-1:0] erlist_dout_sys;

    // hardware register logic
    reg [PIX_IDXW-1:0] er_bpp;
    reg [WORD-1:0] er_canv_dims;
    reg [VRAM_ADDRW-1:0] er_vram_addr_base;

    /* verilator lint_off UNUSEDSIGNAL */  // lower bits unused because of byte addressing
    wire [ER_ADDRW+1:0] er_pc;  // Earthrise program counter (byte addressed)
    /* verilator lint_on UNUSEDSIGNAL */

    // Earthrise start/reset
    reg er_start_sb, er_reset_sb;
    always @(*) er_start_sb = (&we && (addr== ER_START_SB));
    always @(*) er_reset_sb = (&we && (addr== ER_RESET_SB));
    reg er_start, er_reset;
    always @(posedge clk) begin
        er_start <= 0;
        er_reset <= 0;
        if (er_start_sb && ~er_busy) begin
            er_start <= 1;
        end
        if (er_reset_sb && er_busy) begin
            er_reset <= 1;
        end
    end

    // Earthrise status
    wire er_busy, er_instr_invalid;
    wire [WORD-1:0] er_cycle_cnt;

    // reading from erlist takes two cycles
    reg erlist_rd_wait;
    always @(posedge clk) begin
        if (rst) erlist_rd_wait <= 0;
        else erlist_rd_wait <= re && erlist_cs;  // busy for one cycle only after a read from erlist
    end
    assign rbusy = (re && erlist_cs) || erlist_rd_wait;


    always @(posedge clk) begin
        if (rst) begin  // set reasonable defaults to be nice to software devs
            er_bpp <= ER_BPP_INIT;
            er_canv_dims <= ER_CANV_DIMS_INIT;
            er_vram_addr_base <= 0;
            dout <= 0;
        end else if (erlist_rd_wait) begin  // erlist read
            dout <= erlist_dout_sys;
        end else if (&we) begin  // erlist writes go directly to erlist_inst
            case (addr)
                ER_BPP:            er_bpp <= din[PIX_IDXW-1:0];
                ER_CANV_DIMS:      er_canv_dims <= din;
                ER_VRAM_ADDR_BASE: er_vram_addr_base <= din[VRAM_ADDRW-1:0];
                default: ;  // NOP - don't update registers
            endcase
        end else if (re && !erlist_cs) begin
            case (addr)
                ER_BUSY_RO:          dout <= {{WORD-1{1'b0}}, er_busy};
                ER_CYCLE_COUNT_RO:   dout <= er_cycle_cnt;
                ER_PC_RO:            dout <= {{WORD-ER_ADDRW-2{1'b0}}, er_pc};  // -2 because byte addr
                ER_INSTR_INVALID_RO: dout <= {{WORD-1{1'b0}}, er_instr_invalid};
                ER_BPP:              dout <= {{WORD-PIX_IDXW{1'b0}}, er_bpp};
                ER_CANV_DIMS:        dout <= er_canv_dims;
                ER_VRAM_ADDR_BASE:   dout <= {{WORD-VRAM_ADDRW{1'b0}}, er_vram_addr_base};
                default:             dout <= 0;
            endcase
        end
    end


    //
    // Earthrise Command List - supports byte write
    //

    wire [ER_ADDRW-1:0] erlist_addr_er;
    wire [WORD-1:0] erlist_dout_er;

    erlist #(
        .BYTE(BYTE),
        .BYTE_CNT(BYTE_CNT),
        .WORD(WORD),
        .ADDRW(ER_ADDRW),
        .FILE_INIT(FILE_ER_LIST)
    ) erlist_inst (
        .clk(clk),
        .we_sys(we & {4{erlist_cs}}),
        .re_sys(re & erlist_cs),
        .addr_sys(addr[ER_ADDRW-1:0]),
        .din_sys(din),
        .dout_sys(erlist_dout_sys),
        .addr_er(erlist_addr_er),
        .dout_er(erlist_dout_er)
    );

    assign erlist_addr_er = er_pc[ER_ADDRW+1:2];  // command list is word addressed

    // delay counter to make drawing process visible
    reg [$clog2(ER_DRAW_RATE):0] cnt_draw_rate;
    reg er_enable;
    always @(posedge clk) begin
        if (rst) begin
            cnt_draw_rate <= 0;
            er_enable <= 0;
        end else if (en) begin  // if enabled
            if (cnt_draw_rate == ER_DRAW_RATE - 1) begin
                cnt_draw_rate <= 0;
                er_enable <= 1;
            end else begin
                cnt_draw_rate <= cnt_draw_rate + 1;
                er_enable <= 0;
            end
        end
    end

    earthrise #(
        .CORDW(CORDW),
        .WORD(WORD),
        .CANV_SHIFTW(CANV_SHIFTW),
        .COLRW(ER_COLRW),
        .ER_ADDRW(ER_ADDRW),
        .VRAM_ADDRW(VRAM_ADDRW)
    ) earthrise_inst (
        .clk(clk),
        .rst(rst || er_reset),
        .en(er_enable),
        .start(er_start),
        .canv_bpp(er_bpp),
        .canv_dims(er_canv_dims),
        .cmd_list(erlist_dout_er),
        .pc(er_pc),
        .vram_addr_base(er_vram_addr_base),
        .vram_addr(vram_addr),
        .vram_din(vram_din),
        .vram_wmask(vram_wmask),
        .busy(er_busy),
        .cycle_cnt(er_cycle_cnt),
        .instr_invalid(er_instr_invalid)
    );
endmodule
