`timescale 1ns / 1ps

`include "isa.vh"

module stage_if_id (
    input   wire    clk,
    input   wire    rst_n,

    input   wire    clear,
    input   wire    stall,
    input   wire    bj_en,
    input   wire    trap_en,

    input   wire    [31:0] inst_in, 
    input   wire    [63:0] pc_in,
    input   wire    [4:0]  cause_in,
    input   wire    [63:0] tval_in,

    output  wire    [31:0] inst_out, 
    output  wire    [63:0] pc_out,
    output  wire    [4:0]  cause_out,
    output  wire    [63:0] tval_out
);

    dff #(165, 165'b1) dff_stage (
        .clk        (clk),
        .rst_n      (rst_n),
        .clear      (clear | bj_en | trap_en),
        .stall      (stall),
        .d          ({pc_in, cause_in, tval_in, inst_in}),
        .q          ({pc_out, cause_out, tval_out, inst_out})
    );
    
endmodule
