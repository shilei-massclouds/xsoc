`timescale 1ns / 1ps

`include "isa.vh"

module stage_id_ex (
    input wire clk,
    input wire rst_n,

    input wire clear,
    input wire stall,
    input wire bj_en,
    input wire trap_en,

    input wire [63:0] pc_in,
    input wire [4:0]  rd_in,
    input wire [4:0]  rs1_in,
    input wire [4:0]  rs2_in,
    input wire [63:0] data1_in,
    input wire [63:0] data2_in,
    input wire [63:0] imm_in,
    input wire with_imm_in,
    input wire compressed_in,
    alu_ops.dst alu_ops_in,
    io_ops.dst  io_ops_in,
    bj_ops.dst  bj_ops_in,
    sys_ops.dst sys_ops_in,

    output wire [63:0] pc_out,
    output wire [4:0]  rd_out,
    output wire [4:0]  rs1_out,
    output wire [4:0]  rs2_out,
    output wire [63:0] data1_out,
    output wire [63:0] data2_out,
    output wire [63:0] imm_out,
    output wire with_imm_out,
    output wire compressed_out,
    alu_ops.src alu_ops_out,
    io_ops.src  io_ops_out,
    bj_ops.src  bj_ops_out,
    sys_ops.src sys_ops_out
);

    wire [17:0] alu_bits_out;
    wire [23:0] io_bits_out;
    wire [7:0]  bj_bits_out;
    wire [18:0] sys_bits_out;

    wire [17:0] alu_bits_in = {alu_ops_in.add_op, alu_ops_in.sub_op,
                               alu_ops_in.and_op, alu_ops_in.or_op,
                               alu_ops_in.xor_op, alu_ops_in.sll_op,
                               alu_ops_in.srl_op, alu_ops_in.sra_op,
                               alu_ops_in.slt_op, alu_ops_in.lui_op,
                               alu_ops_in.auipc_op, alu_ops_in.mul_op,
                               alu_ops_in.mulh_op, alu_ops_in.mulhsu_op,
                               alu_ops_in.div_op, alu_ops_in.rem_op,
                               alu_ops_in.is_unsign, alu_ops_in.is_word};

    wire [23:0] io_bits_in = {io_ops_in.load_op, io_ops_in.store_op,
                              io_ops_in.amo_add_op, io_ops_in.amo_swap_op,
                              io_ops_in.lr_op, io_ops_in.sc_op,
                              io_ops_in.amo_xor_op, io_ops_in.amo_or_op,
                              io_ops_in.amo_and_op, io_ops_in.amo_min_op,
                              io_ops_in.amo_max_op, io_ops_in.amo_minu_op,
                              io_ops_in.amo_maxu_op,
                              io_ops_in.size, io_ops_in.mask};

    wire [7:0] bj_bits_in = {bj_ops_in.beq_op, bj_ops_in.bne_op,
                             bj_ops_in.blt_op, bj_ops_in.bge_op,
                             bj_ops_in.bltu_op, bj_ops_in.bgeu_op,
                             bj_ops_in.jal_op, bj_ops_in.jalr_op};

    wire [18:0] sys_bits_in = {sys_ops_in.ecall_op, sys_ops_in.ebreak_op,
                              sys_ops_in.mret_op, sys_ops_in.wfi_op,
                              sys_ops_in.csrrw_op, sys_ops_in.csrrs_op,
                              sys_ops_in.csrrc_op, sys_ops_in.csr_addr};

    assign {alu_ops_out.add_op, alu_ops_out.sub_op, alu_ops_out.and_op,
            alu_ops_out.or_op, alu_ops_out.xor_op, alu_ops_out.sll_op,
            alu_ops_out.srl_op, alu_ops_out.sra_op, alu_ops_out.slt_op,
            alu_ops_out.lui_op, alu_ops_out.auipc_op, alu_ops_out.mul_op,
            alu_ops_out.mulh_op, alu_ops_out.mulhsu_op,
            alu_ops_out.div_op, alu_ops_out.rem_op,
            alu_ops_out.is_unsign, alu_ops_out.is_word} = alu_bits_out;

    assign {io_ops_out.load_op, io_ops_out.store_op,
            io_ops_out.amo_add_op, io_ops_out.amo_swap_op,
            io_ops_out.lr_op, io_ops_out.sc_op,
            io_ops_out.amo_xor_op, io_ops_out.amo_or_op,
            io_ops_out.amo_and_op, io_ops_out.amo_min_op,
            io_ops_out.amo_max_op, io_ops_out.amo_minu_op,
            io_ops_out.amo_maxu_op,
            io_ops_out.size, io_ops_out.mask} = io_bits_out;

    assign {bj_ops_out.beq_op, bj_ops_out.bne_op, bj_ops_out.blt_op,
            bj_ops_out.bge_op, bj_ops_out.bltu_op, bj_ops_out.bgeu_op,
            bj_ops_out.jal_op, bj_ops_out.jalr_op} = bj_bits_out;

    assign {sys_ops_out.ecall_op, sys_ops_out.ebreak_op,
            sys_ops_out.mret_op, sys_ops_out.wfi_op,
            sys_ops_out.csrrw_op, sys_ops_out.csrrs_op,
            sys_ops_out.csrrc_op, sys_ops_out.csr_addr} = sys_bits_out;

    dff #(342, 342'b0) dff_stage (
        .clk    (clk),
        .rst_n  (rst_n),
        .clear  (clear | ((bj_en | trap_en) & ~stall)),
        .stall  (stall),
        .d      ({rs1_in, rs2_in, data1_in, data2_in,
                  imm_in, with_imm_in, compressed_in, pc_in, rd_in,
                  alu_bits_in, io_bits_in, bj_bits_in, sys_bits_in}),
        .q      ({rs1_out, rs2_out, data1_out, data2_out,
                  imm_out, with_imm_out, compressed_out, pc_out, rd_out,
                  alu_bits_out, io_bits_out, bj_bits_out, sys_bits_out})
    );

endmodule
