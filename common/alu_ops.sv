interface alu_ops;

    logic add_op;
    logic sub_op;
    logic and_op;
    logic or_op;
    logic xor_op;
    logic sll_op;
    logic srl_op;
    logic sra_op;
    logic slt_op;
    logic lui_op;
    logic auipc_op;
    logic mul_op;
    logic mulh_op;
    logic mulhsu_op;
    logic div_op;
    logic rem_op;

    logic is_unsign;
    logic is_word;

    modport src(output add_op, sub_op, and_op, or_op, xor_op,
                sll_op, srl_op, sra_op, slt_op, lui_op, auipc_op,
                mul_op, mulh_op, mulhsu_op, div_op, rem_op,
                is_unsign, is_word);

    modport dst(input add_op, sub_op, and_op, or_op, xor_op,
                sll_op, srl_op, sra_op, slt_op, lui_op, auipc_op,
                mul_op, mulh_op, mulhsu_op, div_op, rem_op,
                is_unsign, is_word);

endinterface