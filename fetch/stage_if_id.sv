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
    output  wire    [31:0] inst_out, 
    output  wire    [63:0] pc_out
);

    dff #(96, 96'b1) dff_stage (
        .clk        (clk),
        .rst_n      (rst_n),
        .clear      (clear | bj_en | trap_en),
        .stall      (stall),
        .d          ({pc_in, inst_in}),
        .q          ({pc_out, inst_out})
    );
    
endmodule
