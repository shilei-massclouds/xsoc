`timescale 1ns / 1ps

`include "isa.vh"

module jmp_br (
    bj_ops.dst              bj_ops,

    input  wire             stall,
    input  wire [`XMSB:0]   pc,
    input  wire [`XMSB:0]   data1,
    input  wire [`XMSB:0]   imm,
    input  wire [`XMSB:0]   result,

    output wire             bj_en,
    output wire [`XMSB:0]   bj_pc
);

    wire flag = result[0];

    wire take_br = (bj_ops.beq_op & flag) | (bj_ops.bne_op & ~flag) |
                   ((bj_ops.blt_op|bj_ops.bltu_op) & flag) |
                   ((bj_ops.bge_op|bj_ops.bgeu_op) & ~flag);

    assign bj_en = bj_ops.jal_op | (~stall & (bj_ops.jalr_op | take_br));

    wire relative_pc = bj_ops.jal_op |
                       bj_ops.beq_op | bj_ops.bne_op |
                       bj_ops.blt_op | bj_ops.bge_op |
                       bj_ops.bltu_op | bj_ops.bgeu_op;

    assign bj_pc = ({`XLEN{relative_pc}} & (pc + imm)) |
                   ({`XLEN{bj_ops.jalr_op}} & (data1 + imm) &
                   {{(`XLEN - 1){1'b1}}, 1'b0});

endmodule
