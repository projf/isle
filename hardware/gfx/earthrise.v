// Isle.Computer - Earthrise Graphics Engine
// Copyright Will Green and Isle Contributors
// SPDX-License-Identifier: MIT

// NB. Assumes CORDW=16, deriving internal integer coordinate width from this parameter.

`default_nettype none
`timescale 1ns / 1ps

module earthrise #(
    parameter CANV_SHIFTW=3,          // vram address shift width (bits)
    parameter COLRW=8,                // colour/pattern width (bits)
    parameter CORDW=16,               // signed coordinate width (bits)
    parameter ER_ADDRW=10,            // command list address width
    parameter VRAM_ADDRW=14,          // vram address width (bits)
    parameter WORD=32,                // machine word size (bits)
    localparam PIX_IDXW=$clog2(WORD)  // pixel index width (bits)
    ) (
    input  wire clk,                              // clock
    input  wire rst,                              // reset
    input  wire en,                               // enable
    input  wire start,                            // start execution
    input  wire [PIX_IDXW-1:0] canv_bpp,          // canvas bits per pixel
    input  wire [2*CORDW-1:0] canv_dims,          // canvas dimensions
    input  wire [WORD-1:0] cmd_list,              // command list data (32-bit)
    output wire [ER_ADDRW+1:0] pc,                // program counter (byte address)
    input  wire [VRAM_ADDRW-1:0] vram_addr_base,  // base vram word address
    output wire [VRAM_ADDRW-1:0] vram_addr,       // vram word address
    output reg  [WORD-1:0] vram_din,              // vram data in
    output reg  [WORD-1:0] vram_wmask,            // vram write mask
    output wire busy,                             // execution in progress or writing to vram
    output reg  [WORD-1:0] cycle_cnt,             // number of clock cycles to execute command list
    output reg  instr_invalid                     // invalid instruction
    );

    `ifdef DEBUG
        `define debug_er(debug_command) debug_command
    `else
        `define debug_er(debug_command)
    `endif

    localparam ICORDW = 12;  // internal integer coordinate width (bits)

    localparam INSTRW = 16;  // instruction width (bits)
    localparam OPCW   =  4;  // opcode width (bits)
    localparam FUNW   =  4;  // function width
    localparam IMM12  = 12;  // immediate 12 width (bits)
    localparam IMM8   =  8;  // immediate 8 width (bits)

    // register canvas signals
    reg [PIX_IDXW-1:0] canv_bpp_r;
    reg [2*CORDW-1:0] canv_dims_r;
    reg [VRAM_ADDRW-1:0] vram_addr_base_r;

    // drawing position, colour, and wrap
    reg drawing;  // actively drawing a pixel
    reg signed [ICORDW-1:0] x, y;
    reg [COLRW-1:0] colr;  // drawing colour
    reg wraph, wrapv;  // draw wrapping

    // instruction subfields
    reg [OPCW-1:0]  opc;    // opcode
    reg [FUNW-1:0]  fun;    // function
    reg [IMM12-1:0] imm12;  // 12-bit immediate
    reg [COLRW-1:0] imm8;   // 8-bit immediate or options

    // option bit selects
    localparam OPT_FILL  = 0;  // filled shape
    localparam OPT_COLR  = 1;  // colour A or B
    localparam OPT_WRAPH = 4;  // horizontal draw wrap
    localparam OPT_WRAPV = 5;  // vertical draw wrap

    // PC registers
    reg [ER_ADDRW+2:0] pc_reg;  // PC points to next instruction (extra bit to detect overflow)
    /* verilator lint_off UNUSEDSIGNAL */
    reg [ER_ADDRW+1:0] pc_debug;  // currently executing instruction address for debugging
    /* verilator lint_on UNUSEDSIGNAL */
    assign pc = pc_reg[ER_ADDRW+1:0];  // output PC without overflow check bit

    // Earthrise registers
    reg signed [ICORDW-1:0] r0;        // radius 0 - for circle
    reg signed [ICORDW-1:0] xt, yt;    // translation vector
    reg signed [ICORDW-1:0] cnt_fill;  // fill counter for rectangles
    reg [1:0] cnt_draw;  // draw step counter for rectangles and circles
    reg [COLRW-1:0] lca, lcb;  // line colours
    reg [COLRW-1:0] fca, fcb;  // fill colours
    reg [ER_ADDRW+1:0] pc_start;  // start or jump begin at this PC address (byte addressed)

    // translated registers
    reg signed [ICORDW-1:0] tvx0, tvy0;  // translated vertex 0
    reg signed [ICORDW-1:0] tvx1, tvy1;  // translated vertex 1
    reg signed [ICORDW-1:0] tvx2, tvy2;  // translated vertex 2
    /* verilator lint_off UNUSEDSIGNAL */
    reg signed [ICORDW-1:0] tvx3, tvy3;  // translated vertex 3 (for future shape support)
    /* verilator lint_on UNUSEDSIGNAL */

    // sorted vertices (for triangles and rects)
    reg signed [ICORDW-1:0] tvx0s, tvy0s;
    reg signed [ICORDW-1:0] tvx1s, tvy1s;
    reg signed [ICORDW-1:0] tvx2s, tvy2s;

    // line A signals
    reg line_a_start;
    wire line_a_oe, line_a_busy, line_a_valid, line_a_fill;
    reg signed [ICORDW-1:0] line_a_x0, line_a_y0;
    reg signed [ICORDW-1:0] line_a_x1, line_a_y1;
    reg signed [ICORDW-1:0] line_a_xlo, line_a_xhi;
    wire signed [ICORDW-1:0] line_a_x, line_a_y, line_a_xs;

    // line B signals
    reg line_b_start;
    wire line_b_oe, line_b_busy, line_b_valid, line_b_fill;
    reg signed [ICORDW-1:0] line_b_x0, line_b_y0;
    reg signed [ICORDW-1:0] line_b_x1, line_b_y1;
    wire signed [ICORDW-1:0] line_b_x, line_b_y, line_b_xs;

    // fast line signals
    reg fline_start;
    wire fline_valid, fline_busy;
    reg signed [ICORDW-1:0] fline_x0, fline_x1;
    wire signed [ICORDW-1:0] fline_x;
    reg signed [ICORDW-1:0] fline_y;

    // circle signals
    reg circle_start;
    wire circle_oe, circle_valid, circle_busy;
    reg signed [ICORDW-1:0] circle_x0, circle_y0;
    reg signed [ICORDW-1:0] circle_r0;
    wire signed [ICORDW-1:0] circle_xa, circle_ya;
    reg signed [ICORDW-1:0] circle_dx, circle_dy;

    // triangle signals
    reg tri_b_edge;   // flag: drawing edge B0 or B1
    reg tri_a_xdec;   // flag: x-coordinate is decreasing on edge A
    reg tri_b_xdec;   // flag: x-coordinate is decreasing on edge B
    reg tri_b1_skip;  // flag: skip drawing at start of edge B1

    // sort triangle vertices by y-coordinate
    // min uses <= and max uses > so they never select the same vertex (tri_mid_y requires this)
    wire [1:0] tri_min_y = (tvy0 <= tvy1 && tvy0 <= tvy2) ? 0 : (tvy1 <= tvy2) ? 1 : 2;
    wire [1:0] tri_max_y = (tvy0 > tvy1 && tvy0 > tvy2) ? 0 : (tvy1 > tvy2) ? 1 : 2;
    wire [1:0] tri_mid_y = tri_min_y ^ tri_max_y ^ 2'b11;

    // state machine
    localparam IDLE           =  0;
    localparam FINISH         =  1;
    localparam FETCH          =  2;
    localparam DECODE         =  3;
    localparam EXEC           =  4;  // all instr use this state
    localparam LINE_EXEC      =  5;  // drawing instr have their own states
    localparam FLINE_EXEC     =  6;  // used for fast and fill lines
    localparam RECT_INIT      =  7;
    localparam RECT_EXEC      =  8;
    localparam RECTF_INIT     =  9;
    localparam CIRCLE_CALC    = 10;
    localparam CIRCLE_PIX     = 11;
    localparam CIRCLE_FILL_DN = 12;
    localparam CIRCLE_FILL_UP = 13;
    localparam TRI_INIT_B0    = 14;
    localparam TRI_INIT_B1    = 15;
    localparam TRI_WAIT       = 16;
    localparam TRI_LINE_A     = 17;
    localparam TRI_LINE_B     = 18;
    localparam TRI_FILL_INIT  = 19;
    localparam TRI_NEXT_Y     = 20;
    localparam JUMP_WAIT      = 21;

    localparam STATEW = 5;  // state width (bits)
    reg [STATEW-1:0] state, state_return;

    wire agu_draining;  // pixels still in AGU pipeline
    reg busy_exec;  // executing Earthrise commands
    assign busy = busy_exec || agu_draining;

    // select instruction from command list data (upper or lower half from word)
    wire [INSTRW-1:0] instr = pc[1] ? cmd_list[2*INSTRW-1:INSTRW] : cmd_list[INSTRW-1:0];

    // latch start signal so we can act on it later if Earthrise is disabled
    reg start_pending;
    always @(posedge clk) begin
        if (rst) start_pending <= 0;
        else if (start && !busy_exec) start_pending <= 1;
        else if (state == IDLE && en) start_pending <= 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            state_return <= IDLE;
            pc_reg <= 0;
            pc_debug <= 0;
            pc_start <= 0;
            drawing <= 0;
            busy_exec <= 0;
            cycle_cnt <= 0;
            instr_invalid <= 0;
            line_a_start <= 0;
            line_b_start <= 0;
            circle_start <= 0;
            fline_start <= 0;
            // set draw colours to non-zero to be nice to devs
            lca <= 1;
            lcb <= 1;
            fca <= 1;
            fcb <= 1;
            // initialise translate coords to 0 to play nice in simulation
            xt <= 0;
            yt <= 0;
        end else if (en) begin
            drawing <= 0;

            case (state)
                JUMP_WAIT: state <= FETCH;  // wait an extra cycle after changing PC before we can fetch
                FETCH: state <= DECODE;
                DECODE: begin
                    if (pc_reg[ER_ADDRW+2]) state <= FINISH;  // stop if overflow bit of PC set
                    else begin
                        state <= EXEC;
                        pc_reg <= pc_reg + 2;  // next instruction by default (16-bit instr)
                        pc_debug <= pc_reg[ER_ADDRW+1:0];  // save address of current instr for debug
                        opc <= instr[INSTRW-1:INSTRW-OPCW];
                        imm12 <= instr[IMM12-1:0];
                        fun <= instr[COLRW+FUNW-1:COLRW];
                        imm8 <= instr[IMM8-1:0];
                        cnt_draw <= 0;  // draw counter
                        cnt_fill <= 0;  // fill counter
                    end
                end
                EXEC: begin
                    state <= FETCH;
                    case (opc)
                        'h0: tvx0 <= imm12 + xt;  // translated vertex x0
                        'h1: tvy0 <= imm12 + yt;
                        'h2: begin
                            r0  <= imm12;  // radius r0 (not translated)
                            tvx1 <= imm12 + xt;  // translated vertex x1
                        end
                        'h3: tvy1 <= imm12 + yt;
                        'h4: tvx2 <= imm12 + xt;
                        'h5: tvy2 <= imm12 + yt;
                        'h6: tvx3 <= imm12 + xt;
                        'h7: tvy3 <= imm12 + yt;
                        'h8: xt   <= imm12;
                        'h9: yt   <= imm12;
                        'hA: begin
                            pc_start <= imm12[ER_ADDRW+1:0];
                            `debug_er($display("0x%x: pc_next  %x", pc_debug, imm12[ER_ADDRW-1:0]));
                        end
                        'hC: begin  // colour and control
                            case (fun)
                                'h0: lca <= imm8;
                                'h1: lcb <= imm8;
                                'h2: fca <= imm8;
                                'h3: fcb <= imm8;
                                'hA: begin  // 0xCA - Jump (Change Address)
                                    state <= JUMP_WAIT;  // wait a cycle after changing PC
                                    pc_reg <= {1'b0, pc_start};
                                    `debug_er($display("%d - 0x%x: jump     %x", cycle_cnt, pc_debug, pc_start));
                                end
                                'hC: state <= FETCH;  // 0xCC - NOP (Continue)
                                'hE: state <= FINISH;   // 0xCE Stop (CEase)
                                default: begin  // invalid instruction
                                    state <= FINISH;
                                    instr_invalid <= 1;
                                    `debug_er($display("%d - 0x%x: Invalid Instruction - no such instruction '0xC%x'.", cycle_cnt, pc_debug, fun));
                                end
                            endcase
                        end
                        'hD: begin
                            // handle colour once for all shapes; fill colours work for shapes without filled forms
                            colr <= imm8[OPT_FILL] ? (imm8[OPT_COLR] ? fcb : fca)
                                                   : (imm8[OPT_COLR] ? lcb : lca);
                            // draw wrapping
                            wraph <= imm8[OPT_WRAPH];
                            wrapv <= imm8[OPT_WRAPV];
                            // select drawing function
                            case (fun)
                                'h0: begin  // draw pixel
                                    x <= tvx0;
                                    y <= tvy0;
                                    drawing <= 1;
                                    `debug_er($display("%d - 0x%x: pixel    (%d,%d)", cycle_cnt, pc_debug, tvx0, tvy0));
                                end
                                'h1: begin  // draw line
                                    if (tvy0 == tvy1) begin  // fast line
                                        state <= FLINE_EXEC;
                                        state_return <= DECODE;
                                        fline_start <= 1;
                                        fline_x0 <= tvx0;
                                        fline_x1 <= tvx1;
                                        fline_y  <= tvy0;  // use tvy0 for vertical position
                                        `debug_er($display("%d - 0x%x: fline    (%d,%d)->(%d,%d)", cycle_cnt, pc_debug, tvx0, tvy0, tvx1, tvy1));
                                    end else begin
                                        state <= LINE_EXEC;
                                        line_a_start <= 1;   // use line instance A
                                        line_a_x0 <= tvx0;
                                        line_a_y0 <= tvy0;
                                        line_a_x1 <= tvx1;
                                        line_a_y1 <= tvy1;
                                        `debug_er($display("%d - 0x%x: line     (%d,%d)->(%d,%d)", cycle_cnt, pc_debug, tvx0, tvy0, tvx1, tvy1));
                                    end
                                end
                                'h2: begin  // draw circle
                                    if (r0 > 0) begin  // only draw with positive radius
                                        state <= CIRCLE_CALC;
                                        circle_start <= 1;
                                        circle_x0 <= tvx0;
                                        circle_y0 <= tvy0;
                                        circle_r0 <= r0;
                                        `debug_er($display("%d - 0x%x: circle   (%d,%d) r=%d", cycle_cnt, pc_debug, tvx0, tvy0, r0));
                                    end else begin
                                        state <= FETCH;
                                        `debug_er($display("%d - 0x%x: skipping circle - radius not positive (%d,%d) r=%d", cycle_cnt, pc_debug, tvx0, tvy0, r0));
                                    end
                                end
                                'h3: begin  // draw triangle - sort triangle vertices before drawing
                                    state <= TRI_INIT_B0;
                                    tvx0s <= (tri_min_y == 0) ? tvx0 : (tri_min_y == 1) ? tvx1 : tvx2;
                                    tvy0s <= (tri_min_y == 0) ? tvy0 : (tri_min_y == 1) ? tvy1 : tvy2;
                                    tvx1s <= (tri_mid_y == 0) ? tvx0 : (tri_mid_y == 1) ? tvx1 : tvx2;
                                    tvy1s <= (tri_mid_y == 0) ? tvy0 : (tri_mid_y == 1) ? tvy1 : tvy2;
                                    tvx2s <= (tri_max_y == 0) ? tvx0 : (tri_max_y == 1) ? tvx1 : tvx2;
                                    tvy2s <= (tri_max_y == 0) ? tvy0 : (tri_max_y == 1) ? tvy1 : tvy2;
                                    `debug_er($display("%d - 0x%x: triangle (%d,%d) (%d,%d) (%d,%d)", cycle_cnt, pc_debug, tvx0, tvy0, tvx1, tvy1, tvx2, tvy2));
                                end
                                'h4: begin  // draw rect (sort vertices first)
                                    tvx0s <= (tvx0 < tvx1) ? tvx0 : tvx1;
                                    tvy0s <= (tvy0 < tvy1) ? tvy0 : tvy1;
                                    tvx1s <= (tvx0 < tvx1) ? tvx1 : tvx0;
                                    tvy1s <= (tvy0 < tvy1) ? tvy1 : tvy0;
                                    state <= (imm8[OPT_FILL] == 0) ? RECT_INIT : RECTF_INIT;
                                    `debug_er($display("%d - 0x%x: rect     (%d,%d)->(%d,%d)", cycle_cnt, pc_debug, tvx0, tvy0, tvx1, tvy1));
                                end
                                default: begin
                                    state <= FINISH;
                                    instr_invalid <= 1;
                                    `debug_er($display("%d - 0x%x: Invalid Instruction - no such draw function '%x'.", cycle_cnt, pc_debug, fun));
                                end
                            endcase
                        end
                        default: begin
                            state <= FINISH;
                            instr_invalid <= 1;
                            `debug_er($display("%d - 0x%x: Invalid Instruction - no such opcode '%x'.", cycle_cnt, pc_debug, opc));
                        end
                    endcase
                end
                LINE_EXEC: begin
                    if (!line_a_busy) state <= DECODE;
                    line_a_start <= 0;
                    drawing <= line_a_valid;
                    x <= line_a_x;
                    y <= line_a_y;
                end
                CIRCLE_CALC: begin
                    if (circle_valid) begin  // register the result before leaving CIRCLE_CALC
                        circle_dx <= circle_xa;
                        circle_dy <= circle_ya;
                        state <= (imm8[OPT_FILL] == 0) ? CIRCLE_PIX : CIRCLE_FILL_DN;
                    end
                    circle_start <= 0;
                end
                CIRCLE_PIX: begin
                    if (cnt_draw == 3) state <= circle_busy ? CIRCLE_CALC : DECODE;
                    drawing <= 1;
                    cnt_draw <= cnt_draw + 1;
                    case (cnt_draw)
                        'd0: begin x <= circle_x0 - circle_dx; y <= circle_y0 + circle_dy; end
                        'd1: begin x <= circle_x0 + circle_dx; end
                        'd2: begin y <= circle_y0 - circle_dy; end
                        'd3: begin x <= circle_x0 - circle_dx; end
                    endcase
                end
                CIRCLE_FILL_DN: begin
                    state <= FLINE_EXEC;
                    state_return <= CIRCLE_FILL_UP;
                    fline_start <= 1;
                    fline_y  <= circle_y0 + circle_dy;
                    fline_x0 <= circle_x0 + circle_dx;
                    fline_x1 <= circle_x0 - circle_dx;
                end
                CIRCLE_FILL_UP: begin  // fline_x0,fline_x1 unchanged from CIRCLE_FILL_DN
                    state <= FLINE_EXEC;
                    state_return <= circle_busy ? CIRCLE_CALC : DECODE;
                    fline_start <= 1;
                    fline_y <= circle_y0 - circle_dy;
                end
                FLINE_EXEC: begin
                    if (!fline_busy) state <= state_return;
                    fline_start <= 0;
                    drawing <= fline_valid;
                    x <= fline_x;
                    y <= fline_y;
                end
                RECT_INIT: begin
                    state <= RECT_EXEC;
                    line_a_start <= 1;
                    cnt_draw <= cnt_draw + 1;
                    case (cnt_draw)
                        'd0: begin
                            state_return <= RECT_INIT;  // return for second edge
                            line_a_x0 <= tvx0s;
                            line_a_y0 <= tvy0s;
                            line_a_x1 <= tvx1s;
                            line_a_y1 <= tvy0s;
                        end
                        'd1: begin
                            state_return <= RECT_INIT;  // return for third edge
                            line_a_x0 <= tvx0s;
                            line_a_y0 <= tvy1s;
                            line_a_x1 <= tvx1s;
                            line_a_y1 <= tvy1s;
                        end
                        'd2: begin
                            state_return <= RECT_INIT;  // return for fourth edge
                            line_a_x0 <= tvx0s;
                            line_a_y0 <= tvy0s;
                            line_a_x1 <= tvx0s;
                            line_a_y1 <= tvy1s;
                        end
                        default: begin
                            state_return <= DECODE;  // decode next instruction after draw
                            line_a_x0 <= tvx1s;
                            line_a_y0 <= tvy0s;
                            line_a_x1 <= tvx1s;
                            line_a_y1 <= tvy1s;
                        end
                    endcase
                end
                RECT_EXEC: begin
                    if (!line_a_busy) state <= state_return;
                    line_a_start <= 0;
                    drawing <= line_a_valid;
                    x <= line_a_x;
                    y <= line_a_y;
                end
                RECTF_INIT: begin
                    cnt_fill <= cnt_fill + 1;
                    state <= FLINE_EXEC;
                    state_return <= (tvy0s + cnt_fill < tvy1s) ? RECTF_INIT : DECODE;
                    fline_start <= 1;
                    fline_y  <= tvy0s + cnt_fill;
                    fline_x0 <= tvx0s;
                    fline_x1 <= tvx1s;
                end
                TRI_INIT_B0: begin  // A: tv0s -> tv2s; B0: tv0s -> tv1s
                    state <= TRI_WAIT;
                    // line A
                    line_a_x0 <= tvx0s;
                    line_a_y0 <= tvy0s;
                    line_a_x1 <= tvx2s;
                    line_a_y1 <= tvy2s;
                    tri_a_xdec <= (tvx0s > tvx2s);  // does x decrease as we draw A?
                    line_a_start <= 1;
                    // line B0
                    line_b_x0 <= tvx0s;
                    line_b_y0 <= tvy0s;
                    line_b_x1 <= tvx1s;
                    line_b_y1 <= tvy1s;
                    tri_b_edge <= 0;
                    tri_b_xdec <= (tvx0s > tvx1s);  // does x decrease as we draw B0?
                    tri_b1_skip <= 0;  // no skip on B0
                    line_b_start <= 1;
                end
                TRI_INIT_B1: begin  // B1: tv1s -> tv2s
                    state <= TRI_WAIT;
                    line_b_x0 <= tvx1s;
                    line_b_y0 <= tvy1s;
                    line_b_x1 <= tvx2s;
                    line_b_y1 <= tvy2s;
                    tri_b_edge <= 1;
                    tri_b_xdec <= (tvx1s > tvx2s);  // does x decrease as we draw?
                    tri_b1_skip <= 1;  // skip for y for B1 (handled by end of B0)
                    line_b_start <= 1;
                end
                TRI_WAIT: begin
                    state <= tri_b1_skip ? TRI_LINE_B : TRI_LINE_A;  // B line repeats at start of B1: jump ahead one line
                    line_a_start <= 0;  // clear start signals
                    line_b_start <= 0;
                end
                TRI_LINE_A: begin
                    if (line_a_valid) begin
                        drawing <= 1;
                        x <= line_a_x;
                        y <= line_a_y;
                    end
                    if (line_a_fill || (!line_a_busy)) begin
                        state <= TRI_LINE_B;
                        line_a_xlo <= tri_a_xdec ? line_a_x  : line_a_xs;  // x is leftmost with dec x
                        line_a_xhi <= tri_a_xdec ? line_a_xs : line_a_x;   // xs is rightmost with dec x
                    end
                end
                TRI_LINE_B: begin
                    if (line_b_valid) begin
                        drawing <= 1;
                        x <= line_b_x;
                        y <= line_b_y;
                    end
                    if (line_b_fill || (!line_b_busy)) begin
                        state <= TRI_FILL_INIT;
                        fline_y <= line_b_y;
                        // is line A or B on the left-hand side?
                        if (line_a_xlo < (tri_b_xdec ? line_b_xs : line_b_x)) begin
                            fline_x0 <= line_a_xhi + 1;  // line A on left
                            fline_x1 <= (tri_b_xdec ? line_b_x : line_b_xs) - 1;
                        end else begin  // line B on left
                            fline_x0 <= (tri_b_xdec ? line_b_xs : line_b_x) + 1;
                            fline_x1 <= line_a_xlo - 1;
                        end
                    end
                end
                TRI_FILL_INIT: begin
                    if (imm8[OPT_FILL] == 0 || (line_a_busy | line_b_busy) == 0) begin  // skip if unfilled or both lines are complete
                        state <= TRI_NEXT_Y;
                    end else if (tri_b1_skip == 1) begin
                        state <= TRI_NEXT_Y;
                        tri_b1_skip <= 0;
                    end else if (fline_x0 <= fline_x1) begin  // do we have a filled line to draw?
                        state <= FLINE_EXEC;
                        state_return <= TRI_NEXT_Y;
                        fline_start <= 1;
                    end else state <= TRI_NEXT_Y;
                end
                TRI_NEXT_Y: begin
                    if (!line_b_busy) state <= tri_b_edge ? DECODE : TRI_INIT_B1;
                    else state <= TRI_LINE_A;
                end
                FINISH: begin
                    busy_exec <= 0;
                    pc_reg <= 0;  // reset pc: execution always starts from address 0
                    pc_debug <= 0;
                    if (!agu_draining) begin
                        state <= IDLE;
                        `debug_er($display("** DONE ** %d cycles", cycle_cnt));
                    end
                end
                default: begin // IDLE
                    busy_exec <= 0;
                    if (start_pending) begin
                        state <= FETCH;
                        instr_invalid <= 0;
                        busy_exec <= 1;
                        cycle_cnt <= 1;  // cycle counter starts
                        // register canvas signals
                        canv_bpp_r <= canv_bpp;
                        canv_dims_r <= canv_dims;
                        vram_addr_base_r <= vram_addr_base;
                    end
                end
            endcase
        end
        if (!rst && busy_exec && state != FINISH) cycle_cnt <= cycle_cnt + 1;
    end

    assign line_a_oe = (state == LINE_EXEC || state == RECT_EXEC || state == TRI_LINE_A);
    assign line_b_oe = (state == TRI_LINE_B);
    assign circle_oe = (state == CIRCLE_CALC);


    //
    // graphics primitves
    //

    line #(.CORDW(ICORDW)) line_a_inst (
        .clk(clk),
        .rst(rst),
        .start(line_a_start),
        .oe(line_a_oe && en),
        .x0(line_a_x0),
        .y0(line_a_y0),
        .x1(line_a_x1),
        .y1(line_a_y1),
        .x(line_a_x),
        .y(line_a_y),
        .xs(line_a_xs),
        .fill(line_a_fill),
        .busy(line_a_busy),
        .valid(line_a_valid)
    );

    line #(.CORDW(ICORDW)) line_b_inst (
        .clk(clk),
        .rst(rst),
        .start(line_b_start),
        .oe(line_b_oe && en),
        .x0(line_b_x0),
        .y0(line_b_y0),
        .x1(line_b_x1),
        .y1(line_b_y1),
        .x(line_b_x),
        .y(line_b_y),
        .xs(line_b_xs),
        .fill(line_b_fill),
        .busy(line_b_busy),
        .valid(line_b_valid)
    );

    fline #(.CORDW(ICORDW)) fline_inst (
        .clk(clk),
        .rst(rst),
        .start(fline_start),
        .oe(en),
        .x0(fline_x0),
        .x1(fline_x1),
        .x(fline_x),
        .busy(fline_busy),
        .valid(fline_valid)
    );

    circle #(.CORDW(ICORDW)) circle_inst (
        .clk(clk),
        .rst(rst),
        .start(circle_start),
        .oe(circle_oe && en),
        .r0(circle_r0),
        .xa(circle_xa),
        .ya(circle_ya),
        .busy(circle_busy),
        .valid(circle_valid)
    );


    //
    // draw address generation
    //

    wire [PIX_IDXW-1:0] pix_idx;  // pixel index within word
    wire draw_addr_valid;  // we only want to write to vram for valid addresses
    reg [CANV_SHIFTW-1:0] addr_shift;  // to separate vram address and pix_idx
    wire [2*CORDW-1:0] pix_coord = {{(CORDW-ICORDW){y[ICORDW-1]}}, y,  // sign extend from 12 bits
                                    {(CORDW-ICORDW){x[ICORDW-1]}}, x};
    canv_draw_agu #(
        .CORDW(CORDW),
        .WORD(WORD),
        .ADDRW(VRAM_ADDRW),
        .SHIFTW(CANV_SHIFTW)
    ) canv_draw_agu_inst (
        .clk(clk),
        .rst(rst),
        .en(en),
        .canv_dims(canv_dims_r),
        .pix_coord(pix_coord),
        .vram_addr_base(vram_addr_base_r),
        .addr_shift(addr_shift),
        .wraph(wraph),
        .wrapv(wrapv),
        .vram_addr(vram_addr),
        .pix_idx(pix_idx),
        .valid(draw_addr_valid)
    );

    // delay write enable to match address calculation - output in vram_we_sr[0]
    localparam ADDR_LAT = 4;  // ensure this matches canv_draw_agu
    reg [ADDR_LAT-1:0] vram_we_sr;
    always @(posedge clk) begin
        if (rst) vram_we_sr <= 0;
        else if (en) vram_we_sr <= {drawing, vram_we_sr[ADDR_LAT-1:1]};
    end

    assign agu_draining = |vram_we_sr;  // address generation unit draining

    // delay colour to match address calculation - output in colr_p4
    reg [COLRW-1:0] colr_p1, colr_p2, colr_p3, colr_p4;
    always @(posedge clk) begin
        if (en) begin
            colr_p1 <= colr;
            colr_p2 <= colr_p1;
            colr_p3 <= colr_p2;
            colr_p4 <= colr_p3;
        end
    end

    // determine address shift from bits per pixel (BPP)
    always @(*) begin
        case(canv_bpp_r)
            8: addr_shift = 2;  // 256 colour
            4: addr_shift = 3;  // 16 colour
            2: addr_shift = 4;  // 4 colour
            1: addr_shift = 5;  // 2 colour
            default: addr_shift = 3;  // 16 colour by default
        endcase
    end

    // pixel placement within vram word
    wire [PIX_IDXW:0] pix_bits = WORD >> addr_shift;  // bits per pixel (support full word)
    /* verilator lint_off WIDTHEXPAND */
    wire [PIX_IDXW-1:0] pix_bit_pos = pix_idx << (PIX_IDXW - addr_shift);  // bit offset in word
    /* verilator lint_on WIDTHEXPAND */
    wire [WORD-1:0] pix_mask = (1 << pix_bits) - 1;  // word mask of pixel's bits

    // vram write mask
    always @(*) begin
        if (draw_addr_valid && vram_we_sr[0]) begin  // valid address and write enable
            vram_wmask = pix_mask << pix_bit_pos;  // shift pixel mask into position
        end else vram_wmask = 0;
    end

    // vram data in
    always @(*) begin
        /* verilator lint_off WIDTHEXPAND */
        vram_din = (colr_p4 & pix_mask) << pix_bit_pos;  // shift masked colour into position
        /* verilator lint_on WIDTHEXPAND */
    end
endmodule
