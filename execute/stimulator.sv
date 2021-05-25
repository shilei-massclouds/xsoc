`timescale 1ns / 1ps

`include "isa.vh"

module stimulator (
    alu_ops.src         alu_ops,
    io_ops.src          io_ops,
    bj_ops.src          bj_ops,
    sys_ops.src         sys_ops,

    output wire         clear,
    output wire         stall,

    output wire         compressed,

    output reg  [63:0]  pc,
    output reg  [4:0]   rd,
    output reg  [4:0]   rs1,
    output reg  [4:0]   rs2,
    output reg  [63:0]  data1,
    output reg  [63:0]  data2,
    output reg  [63:0]  imm,
    output reg          with_imm,

    output reg  [4:0]   ma_rd,
    output reg  [63:0]  ma_out,
    output reg  [4:0]   wb_rd,
    output reg  [63:0]  wb_out
);

    initial begin
        pc <= 64'h400;
        rd <= 5'h5;
        rs1 <= 5'h3;
        rs2 <= 5'h4;
        data1 <= 64'd256;
        data2 <= 64'd512;
        imm <= 64'd1024;
        with_imm <= `DISABLE;
        ma_rd <= 5'h3;
        ma_out <= 64'hDDAA;
        wb_rd <= 5'h6;
        wb_out <= 64'hDCBA;
        alu_ops.add_op <= `ENABLE;
        alu_ops.sub_op <= `DISABLE;
        alu_ops.and_op <= `DISABLE;
        alu_ops.or_op <= `DISABLE;
        alu_ops.xor_op <= `DISABLE;
        alu_ops.sll_op <= `DISABLE;
        alu_ops.srl_op <= `DISABLE;
        alu_ops.sra_op <= `DISABLE;
        alu_ops.slt_op <= `DISABLE;
        io_ops.load_op <= `ENABLE;
        io_ops.store_op <= `ENABLE;
    end

endmodule
