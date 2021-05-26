`timescale 1ns / 1ps

`include "csr.vh"

module system_ctl (
    sys_ops.dst         sys_ops,

    output wire [4:0]   e_cause,
    output wire [63:0]  e_tval
);

    wire op_csr = sys_ops.csrrw_op | sys_ops.csrrs_op | sys_ops.csrrc_op;

    assign e_tval = {12{op_csr}} & sys_ops.csr_addr;

    assign e_cause = ({5{sys_ops.ecall_op}}  & `SYSOP_ECALL)  |
                     ({5{sys_ops.ebreak_op}} & `SYSOP_EBREAK) |
                     ({5{sys_ops.mret_op}}   & `SYSOP_RET)    |
                     ({5{sys_ops.csrrw_op}}  & `SYSOP_CSR_W)  |
                     ({5{sys_ops.csrrs_op}}  & `SYSOP_CSR_S)  |
                     ({5{sys_ops.csrrc_op}}  & `SYSOP_CSR_C);

endmodule
