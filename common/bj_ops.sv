interface bj_ops;

    logic beq_op;
    logic bne_op;
    logic blt_op;
    logic bge_op;
    logic bltu_op;
    logic bgeu_op;
    logic jal_op;
    logic jalr_op;

    modport src(output beq_op, bne_op, blt_op, bge_op, bltu_op, bgeu_op,
                jal_op, jalr_op);
    modport dst(input beq_op, bne_op, blt_op, bge_op, bltu_op, bgeu_op,
                jal_op, jalr_op);

endinterface