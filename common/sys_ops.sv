interface sys_ops;

    logic ecall_op;
    logic ebreak_op;
    logic mret_op;
    logic wfi_op;

    logic csrrw_op;
    logic csrrs_op;
    logic csrrc_op;

    logic [11:0] csr_addr;

    modport src(output ecall_op, ebreak_op, mret_op, wfi_op,
                csrrw_op, csrrs_op, csrrc_op, csr_addr);
    modport dst(input ecall_op, ebreak_op, mret_op, wfi_op,
                csrrw_op, csrrs_op, csrrc_op, csr_addr);

endinterface