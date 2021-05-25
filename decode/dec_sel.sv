`define MUX(SEL, OP, OPS) \
    assign id_``OPS``.OP = SEL ? ``OPS``_16.OP : ``OPS``_32.OP

`define ALU_MUX(SEL, OP) `MUX(SEL, OP, alu_ops)
`define IO_MUX(SEL, OP) `MUX(SEL, OP, io_ops)
`define BJ_MUX(SEL, OP) `MUX(SEL, OP, bj_ops)
`define SYS_MUX(SEL, OP) `MUX(SEL, OP, sys_ops)

module dec_sel (
    input wire  compressed,
    alu_ops.src id_alu_ops,
    alu_ops.dst alu_ops_16,
    alu_ops.dst alu_ops_32,
    io_ops.src  id_io_ops,
    io_ops.dst  io_ops_16,
    io_ops.dst  io_ops_32,
    bj_ops.src  id_bj_ops,
    bj_ops.dst  bj_ops_16,
    bj_ops.dst  bj_ops_32,
    sys_ops.src id_sys_ops,
    sys_ops.dst sys_ops_16,
    sys_ops.dst sys_ops_32
);

    `ALU_MUX(compressed, add_op);
    `ALU_MUX(compressed, sub_op);
    `ALU_MUX(compressed, and_op);
    `ALU_MUX(compressed, or_op);
    `ALU_MUX(compressed, xor_op);
    `ALU_MUX(compressed, sll_op);
    `ALU_MUX(compressed, srl_op);
    `ALU_MUX(compressed, sra_op);
    `ALU_MUX(compressed, slt_op);
    `ALU_MUX(compressed, lui_op);
    `ALU_MUX(compressed, auipc_op);
    `ALU_MUX(compressed, mul_op);
    `ALU_MUX(compressed, mulh_op);
    `ALU_MUX(compressed, mulhsu_op);
    `ALU_MUX(compressed, div_op);
    `ALU_MUX(compressed, rem_op);
    `ALU_MUX(compressed, is_unsign);
    `ALU_MUX(compressed, is_word);

    `IO_MUX(compressed, load_op);
    `IO_MUX(compressed, store_op);
    `IO_MUX(compressed, amo_add_op);
    `IO_MUX(compressed, amo_swap_op);
    `IO_MUX(compressed, lr_op);
    `IO_MUX(compressed, sc_op);
    `IO_MUX(compressed, amo_xor_op);
    `IO_MUX(compressed, amo_or_op);
    `IO_MUX(compressed, amo_and_op);
    `IO_MUX(compressed, amo_min_op);
    `IO_MUX(compressed, amo_max_op);
    `IO_MUX(compressed, amo_minu_op);
    `IO_MUX(compressed, amo_maxu_op);
    `IO_MUX(compressed, size);
    `IO_MUX(compressed, mask);

    `BJ_MUX(compressed, beq_op);
    `BJ_MUX(compressed, bne_op);
    `BJ_MUX(compressed, blt_op);
    `BJ_MUX(compressed, bge_op);
    `BJ_MUX(compressed, bltu_op);
    `BJ_MUX(compressed, bgeu_op);
    `BJ_MUX(compressed, jal_op);
    `BJ_MUX(compressed, jalr_op);

    `SYS_MUX(compressed, ecall_op);
    `SYS_MUX(compressed, ebreak_op);
    `SYS_MUX(compressed, mret_op);
    `SYS_MUX(compressed, wfi_op);
    `SYS_MUX(compressed, csrrw_op);
    `SYS_MUX(compressed, csrrs_op);
    `SYS_MUX(compressed, csrrc_op);
    `SYS_MUX(compressed, csr_addr);

endmodule