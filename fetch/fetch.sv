`timescale 1ns / 1ps

`include "isa.vh"

module fetch (
    input   wire    clk,
    input   wire    rst_n,

    input   wire    stall,
    input   wire    clear,

    input   wire    trap_en,
    input   wire    [63:0] trap_pc,
    input   wire    bj_en,
    input   wire    [63:0] bj_pc,

    input   wire    invalid,

    input   wire    page_fault,
    input   wire    [63:0] tval,

    output  wire    [31:0] inst,
    output  wire    [63:0] pc,

    output  wire    [4:0]  cause_out,
    output  wire    [63:0] tval_out,

    output  wire    request,
    tilelink.master bus
);

    wire [63:0] _pc;
    wire inst_valid;
    wire inst_comp;
    wire [31:0] _inst;

    wire [4:0]  cause_in = page_fault ? `SYSOP_INST_PAGE_FAULT : 5'b0;
    wire [63:0] tval_in  = page_fault ? tval : 64'b0;

    pc_ctl pc_ctl (
        .clk        (clk       ),
        .rst_n      (rst_n     ),
        .stall      (stall     ),
        .trap_en    (trap_en   ),
        .trap_pc    (trap_pc   ),
        .bj_en      (bj_en     ),
        .bj_pc      (bj_pc     ),
        .inst_valid (inst_valid),
        .inst_comp  (inst_comp ),
        .pc         (_pc       )
    );

    instcache instcache (
        .clk        (clk       ),
        .rst_n      (rst_n     ),
        .invalid    (invalid   ),
        .page_fault (page_fault),
        .pc         (_pc       ),
        .inst_valid (inst_valid),
        .inst_comp  (inst_comp ),
        .inst       (_inst     ),
        .request    (request   ),
        .bus        (bus       )
    );

    stage_if_id stage_if_id (
        .clk      (clk      ),
        .rst_n    (rst_n    ),
        .clear    (clear    ),
        .stall    (stall    ),
        .bj_en    (bj_en    ),
        .trap_en  (trap_en  ),
        .inst_in  (_inst    ),
        .pc_in    (_pc      ),
        .cause_in (cause_in ),
        .tval_in  (tval_in  ),
        .inst_out (inst     ),
        .pc_out   (pc       ),
        .cause_out(cause_out),
        .tval_out (tval_out )
    );

    dbg_fetch u_dbg_fetch (
        .clk   (clk   ),
        .rst_n (rst_n ),
        .inst  (_inst ),
        .pc    (_pc   ),
        .trap_en(trap_en),
        .bj_en (bj_en ),
        .stall (stall ),
        .page_fault(page_fault),
        .invalid(invalid),
        .cause (cause_out),
        .tval  (tval_out)
    );

endmodule
