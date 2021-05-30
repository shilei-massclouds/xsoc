`timescale 1ns / 1ps

`include "csr.vh"

module csr (
    input  wire         clk,
    input  wire         rst_n,

    input  wire [63:0]  pc,
    input  wire [4:0]   cause,
    input  wire [63:0]  tval,
    input  wire [63:0]  wdata,
    output wire [63:0]  rdata,
    output wire         r_valid,

    output wire [63:0]  satp,
    output wire         invalid,

    output wire         trap_en,
    output wire [63:0]  trap_pc
);

    reg  [1:0]  priv;
    bit  [63:0] csr[4096];

    assign r_valid = (cause == `SYSOP_CSR_W) ||
                     (cause == `SYSOP_CSR_S) ||
                     (cause == `SYSOP_CSR_C);

    assign rdata = r_valid ? csr[tval] : 64'b0;

    assign satp = csr[`SATP];

    wire except = (cause == `MCAUSE_LOAD_PAGE_FAULT ||
                   cause == `MCAUSE_INST_PAGE_FAULT ||
                   cause == `SYSOP_ECALL);

    assign invalid = r_valid & (tval == `SATP);
    assign trap_en = (except || (cause == `SYSOP_RET) || invalid);

    assign trap_pc = except ? csr[`MTVEC] :
                     (cause == `SYSOP_RET) ? csr[`MEPC] :
                     invalid ? (pc + 4) : 64'b0;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            priv <= `M_MODE;
            csr[`MISA] <= MISA_INIT_VAL;
        end else begin
            if (cause == `MCAUSE_LOAD_PAGE_FAULT ||
                cause == `MCAUSE_INST_PAGE_FAULT ||
                cause == `SYSOP_ECALL) begin

                csr[`MCAUSE] <= cause;

                if (cause == `SYSOP_ECALL) begin
                    if (priv == `U_MODE) begin
                        csr[`MCAUSE] <= `MCAUSE_ECALL_FROM_U_MODE;
                    end else if (priv == `S_MODE) begin
                        csr[`MCAUSE] <= `MCAUSE_ECALL_FROM_S_MODE;
                    end else begin
                        csr[`MCAUSE] <= `MCAUSE_ECALL_FROM_M_MODE;
                    end
                end

                csr[`MEPC] <= pc;
                csr[`MTVAL] <= tval;

                csr[`MSTATUS][`MS_MPIE] <= csr[`MSTATUS][`MS_MIE];
                csr[`MSTATUS][`MS_MIE] <= `DISABLE;

                csr[`MSTATUS][`MS_MPP] <= priv;
                priv <= `M_MODE;

                $display($time,, "Except(%0x): tvec(%0x)", cause, csr[`MTVEC]);
            end else if (cause == `SYSOP_RET) begin
                csr[`MSTATUS][`MS_MIE] <= csr[`MSTATUS][`MS_MPIE];
                priv <= csr[`MSTATUS][`MS_MPP];
            end else if (cause == `SYSOP_CSR_W) begin
                csr[tval] <= wdata;
            end else if (cause == `SYSOP_CSR_S) begin
                csr[tval] <= csr[tval] | wdata;
            end else if (cause == `SYSOP_CSR_C) begin
                csr[tval] <= csr[tval] & ~wdata;
            end
        end
    end

endmodule
