`timescale 1ns / 1ps

`include "isa.vh"

module alu (
    alu_ops.dst             alu_ops,
    io_ops.dst              io_ops,
    bj_ops.dst              bj_ops,

    input  wire             compressed,
    input  wire [`XMSB:0]   pc,
    input  wire [`XMSB:0]   fwd1,
    input  wire [`XMSB:0]   fwd2,
    input  wire [`XMSB:0]   imm,
    input  wire             with_imm,

    output wire [`XMSB:0]   result
);

    wire zf, cf, sf, of;

    wire [`XMSB:0] data1;
    wire [`XMSB:0] data2;

    assign data1 = fwd1;
    assign data2 = with_imm ? imm : fwd2;

    wire is_signed = ~alu_ops.is_unsign;

    wire amo_op = io_ops.amo_add_op |
                  io_ops.amo_min_op | io_ops.amo_max_op |
                  io_ops.amo_minu_op | io_ops.amo_maxu_op |
                  io_ops.amo_xor_op | io_ops.amo_or_op |
                  io_ops.amo_and_op | io_ops.amo_swap_op;

    wire blt_bge = bj_ops.blt_op | bj_ops.bge_op |
                   bj_ops.bltu_op | bj_ops.bgeu_op;

    wire [`ALU_MSB:0] operand1 = {is_signed & data1[`XMSB], data1};
    wire [`ALU_MSB:0] operand2 = {is_signed & data2[`XMSB], data2};

    wire sub = alu_ops.sub_op | alu_ops.slt_op |
               bj_ops.beq_op | bj_ops.bne_op | blt_bge;
    wire [`ALU_MSB:0] addend = (sub ? ~operand2 : operand2) + sub;

    wire [`XMSB:0] ret;
    assign {cf, ret} = operand1 + addend;

    assign zf = ~(|ret);
    assign sf = ret[`XMSB];
    assign of = cf ^ sf;

    wire [63:0] shdata = alu_ops.is_word ? {32'b0, data1[31:0]} : data1;
    wire [5:0] shamt = alu_ops.is_word ? {1'b0, data2[4:0]} : data2[5:0];
    wire [63:0] sll_ret = shdata << shamt;
    wire [63:0] srl_ret = shdata >> shamt;

    wire [63:0] shdata_a = alu_ops.is_word ?
                           {{32{data1[31]}}, data1[31:0]} : data1;
    wire [63:0] sra_ret = $signed(shdata_a) >>> shamt;

    wire [63:0] lui_ret = data2;
    wire [63:0] auipc_ret = pc + data2;

    wire [127:0] muls_ret = $signed(data1) * $signed(data2);
    wire [127:0] mulu_ret = data1 * data2;
    wire [127:0] mul_ret = is_signed ? muls_ret : mulu_ret;
    wire [127:0] mulsu_ret = $signed(data1) * data2;

    wire [127:0] divs_ret = $signed(data1) / $signed(data2);
    wire [127:0] divu_ret = data1 / data2;
    wire [127:0] div_ret = is_signed ? divs_ret : divu_ret;

    wire [127:0] rems_ret = $signed(data1) % $signed(data2);
    wire [127:0] remu_ret = data1 % data2;
    wire [127:0] rem_ret = is_signed ? rems_ret : remu_ret;

    wire [`XMSB:0] pc_inc = compressed ? 2 : 4;

    wire [63:0] _out =
        ({64{alu_ops.add_op}} & ret) |
        ({64{alu_ops.sub_op}} & ret) |
        ({64{alu_ops.slt_op}} & (cf ? 64'b1 : 64'b0)) |
        ({64{alu_ops.and_op}} & (data1 & data2)) |
        ({64{alu_ops.or_op}} & (data1 | data2)) |
        ({64{alu_ops.xor_op}} & (data1 ^ data2)) |
        ({64{alu_ops.sll_op}} & sll_ret) |
        ({64{alu_ops.srl_op}} & srl_ret) |
        ({64{alu_ops.sra_op}} & sra_ret) |
        ({64{alu_ops.lui_op}} & lui_ret) |
        ({64{alu_ops.auipc_op}} & auipc_ret) |
        ({64{alu_ops.mul_op}} & mul_ret[63:0]) |
        ({64{alu_ops.mulh_op}} & mul_ret[127:64]) |
        ({64{alu_ops.mulhsu_op}} & mulsu_ret[127:64]) |
        ({64{alu_ops.div_op}} & div_ret[63:0]) |
        ({64{alu_ops.rem_op}} & rem_ret[63:0]) |
        ({64{amo_op}} & data1) |
        ({64{bj_ops.beq_op|bj_ops.bne_op}} & {63'b0, zf}) |
        ({63'b0, blt_bge & cf}) |
        ({64{bj_ops.jal_op | bj_ops.jalr_op}} & (pc + pc_inc));

    assign result = alu_ops.is_word ?
                    ({{32{_out[31]}}, _out[31:0]}) : _out;

endmodule
