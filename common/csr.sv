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

    output reg          trap_en,
    output reg  [63:0]  trap_pc
);

    reg  [1:0]  priv;
    bit  [63:0] csr[4096];

    assign r_valid = (cause == `SYSOP_CSR_W) ||
                     (cause == `SYSOP_CSR_S) ||
                     (cause == `SYSOP_CSR_C);

    assign rdata = r_valid ? csr[tval] : 64'b0;

    assign satp = csr[`SATP];

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            priv <= `M_MODE;
            csr[`MISA] <= MISA_INIT_VAL;
            trap_en <= `DISABLE;
            trap_pc <= 64'b0;
        end else begin
            trap_en <= `DISABLE;
            trap_pc <= 64'b0;

            if (cause == `SYSOP_ECALL) begin
                if (priv == `U_MODE) begin
                    csr[`MCAUSE] <= `MCAUSE_ECALL_FROM_U_MODE;
                end else if (priv == `S_MODE) begin
                    csr[`MCAUSE] <= `MCAUSE_ECALL_FROM_S_MODE;
                end else begin
                    csr[`MCAUSE] <= `MCAUSE_ECALL_FROM_M_MODE;
                end

                csr[`MEPC] <= pc;
                csr[`MTVAL] <= 64'b0;

                csr[`MSTATUS][`MS_MPIE] <= csr[`MSTATUS][`MS_MIE];
                csr[`MSTATUS][`MS_MIE] <= `DISABLE;

                csr[`MSTATUS][`MS_MPP] <= priv;
                priv <= `M_MODE;

                trap_en <= `ENABLE;
                trap_pc <= csr[`MTVEC];
            end else if (cause == `SYSOP_RET) begin
                csr[`MSTATUS][`MS_MIE] <= csr[`MSTATUS][`MS_MPIE];
                priv <= csr[`MSTATUS][`MS_MPP];

                trap_en <= `ENABLE;
                trap_pc <= csr[`MEPC];
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
