`timescale 1ns / 1ps

`include "csr.vh"

module csr_ecall (
    sys_ops.dst         sys_ops,

    input  wire [4:0]   cause_in,
    input  wire [63:0]  tval_in,

    output wire [4:0]   cause_out,
    output wire [63:0]  tval_out
);

    wire op_csr = sys_ops.csrrw_op | sys_ops.csrrs_op | sys_ops.csrrc_op;

    assign tval_out = cause_in ? tval_in : {12{op_csr}} & sys_ops.csr_addr;

    assign cause_out = cause_in ? cause_in :
                       (({5{sys_ops.ecall_op}}  & `SYSOP_ECALL)  |
                        ({5{sys_ops.ebreak_op}} & `SYSOP_EBREAK) |
                        ({5{sys_ops.mret_op}}   & `SYSOP_RET)    |
                        ({5{sys_ops.csrrw_op}}  & `SYSOP_CSR_W)  |
                        ({5{sys_ops.csrrs_op}}  & `SYSOP_CSR_S)  |
                        ({5{sys_ops.csrrc_op}}  & `SYSOP_CSR_C));

endmodule
