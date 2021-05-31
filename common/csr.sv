`timescale 1ns / 1ps

`include "csr.vh"

module csr (
    input  wire         clk,
    input  wire         rst_n,

    input  wire [63:0]  pc,
    input  wire [4:0]   op,
    input  wire [63:0]  tval,
    input  wire [63:0]  wdata,
    output wire [63:0]  rdata,
    output wire         r_valid,

    output wire [1:0]   priv,
    output wire [63:0]  satp,
    output wire         invalid,

    output wire         trap_en,
    output wire [63:0]  trap_pc
);

    reg  [1:0]  _priv;
    bit  [63:0] csr[4096];

    assign priv = _priv;

    assign r_valid = (op == `SYSOP_CSR_W) ||
                     (op == `SYSOP_CSR_S) ||
                     (op == `SYSOP_CSR_C);

    assign rdata = r_valid ? csr[tval] : 64'b0;

    assign satp = csr[`SATP];

    wire except = op[4];
    wire [3:0] cause = op[3:0];
    wire medeleg = csr[`MEDELEG][cause];

    assign invalid = r_valid & (tval == `SATP);
    assign trap_en = (except || (op == `SYSOP_RET) || invalid);

    assign trap_pc = except ? csr[`MTVEC] :
                     (op == `SYSOP_RET) ? csr[`MEPC] :
                     invalid ? (pc + 4) : 64'b0;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            _priv <= `M_MODE;
            csr[`MISA] <= MISA_INIT_VAL;
        end else begin
            if (except) begin
                csr[`MCAUSE] <= {60'b0, cause};

                csr[`MEPC] <= pc;
                csr[`MTVAL] <= tval;

                csr[`MSTATUS][`MS_MPIE] <= csr[`MSTATUS][`MS_MIE];
                csr[`MSTATUS][`MS_MIE] <= `DISABLE;

                csr[`MSTATUS][`MS_MPP] <= _priv;
                _priv <= `M_MODE;

                $display($time,, "Except(%0x): tvec(%0x); medeleg(%0x:%0x)",
                         op, csr[`MTVEC], csr[`MEDELEG], medeleg);
            end else if (op == `SYSOP_RET) begin
                csr[`MSTATUS][`MS_MIE] <= csr[`MSTATUS][`MS_MPIE];
                _priv <= csr[`MSTATUS][`MS_MPP];
            end else if (op == `SYSOP_CSR_W) begin
                $display($time,, "CSRW write[%0x]: %0x", tval, wdata);
                csr[tval] <= wdata;
            end else if (op == `SYSOP_CSR_S) begin
                $display($time,, "CSRS write[%0x]: %0x", tval, wdata);
                csr[tval] <= csr[tval] | wdata;
            end else if (op == `SYSOP_CSR_C) begin
                $display($time,, "CSRC write[%0x]: %0x", tval, wdata);
                csr[tval] <= csr[tval] & ~wdata;
            end
        end
    end

endmodule
