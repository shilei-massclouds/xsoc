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

    output  wire    [31:0] inst,
    output  wire    [63:0] pc,

    output  wire    request,
    tilelink.master bus
);

    wire [63:0] _pc;
    wire inst_valid;
    wire inst_comp;
    wire [31:0] _inst;

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
        .inst_out (inst     ),
        .pc_out   (pc       )
    );

    dbg_fetch u_dbg_fetch (
        .clk   (clk   ),
        .rst_n (rst_n ),
        .inst  (_inst ),
        .pc    (_pc   )
    );

endmodule
