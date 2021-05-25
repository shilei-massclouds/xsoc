`timescale 1ns / 1ps

`include "csr_addr.vh"

module system_ctl (
    input  wire clk,
    input  wire rst_n,

    sys_ops.dst           sys_ops,
    input  wire [`XMSB:0] pc,
    input  wire [`XMSB:0] data1,
    input  wire [`XMSB:0] imm,
    input  wire           with_imm,

    output wire [`XMSB:0] csr_data,
    output reg            trap_en,
    output reg  [`XMSB:0] trap_pc
);

    localparam MCAUSE_S_SOFTWARE_INTR = {1'b1, 63'h1};
    localparam MCAUSE_M_SOFTWARE_INTR = {1'b1, 63'h3};
    localparam MCAUSE_S_TIMER_INTR    = {1'b1, 63'h5};
    localparam MCAUSE_M_TIMER_INTR    = {1'b1, 63'h7};
    localparam MCAUSE_S_EXTERNAL_INTR = {1'b1, 63'h9};
    localparam MCAUSE_M_EXTERNAL_INTR = {1'b1, 63'hb};

    localparam MCAUSE_INST_ADDR_MISALIGNED  = 64'h0;
    localparam MCAUSE_INST_ACCESS_FAULT     = 64'h1;
    localparam MCAUSE_ILLEGAL_INST          = 64'h2;
    localparam MCAUSE_BREAK_POINT           = 64'h3;
    localparam MCAUSE_LOAD_ADDR_MISALIGNED  = 64'h4;
    localparam MCAUSE_LOAD_ACCESS_FAULT     = 64'h5;
    localparam MCAUSE_STORE_ADDR_MISALIGNED = 64'h6;
    localparam MCAUSE_STORE_ACCESS_FAULT    = 64'h7;
    localparam MCAUSE_ECALL_FROM_U_MODE     = 64'h8;
    localparam MCAUSE_ECALL_FROM_S_MODE     = 64'h9;
    localparam MCAUSE_ECALL_FROM_M_MODE     = 64'hb;
    localparam MCAUSE_INST_PAGE_FAULT       = 64'hc;
    localparam MCAUSE_LOAD_PAGE_FAULT       = 64'hd;
    localparam MCAUSE_STORE_PAGE_FAULT      = 64'hf;

    reg [1:0]       priv;
    bit [`XMSB:0]   csr[4096];

    wire [`XMSB:0] wdata = with_imm ? imm : data1;

    wire op_csr = sys_ops.csrrw_op |
                  sys_ops.csrrs_op |
                  sys_ops.csrrc_op;

    assign csr_data = op_csr ? csr[sys_ops.csr_addr] : 64'b0;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            priv <= `M_MODE;
            csr[`MISA] <= MISA_INIT_VAL;
            trap_en <= `DISABLE;
            trap_pc <= 64'b0;
        end else begin
            trap_en <= `DISABLE;
            trap_pc <= 64'b0;

            if (sys_ops.ecall_op | sys_ops.ebreak_op) begin
                /*
                $display($time,, "ecall/ebreak: mtvec(%x) priv(%x) pc(%x)",
                         csr[`MTVEC], priv, pc);
                */
                csr[`MEPC] <= pc;
                csr[`MCAUSE] <= MCAUSE_ECALL_FROM_S_MODE;
                csr[`MTVAL] <= 64'b0;

                csr[`MSTATUS][`MS_MPIE] <= csr[`MSTATUS][`MS_MIE];
                csr[`MSTATUS][`MS_MIE] <= `DISABLE;

                csr[`MSTATUS][`MS_MPP] <= priv;
                priv <= `M_MODE;

                trap_en <= `ENABLE;
                trap_pc <= csr[`MTVEC];
            end else if (sys_ops.mret_op) begin
                /*
                $display($time,, "mret: mepc(%x) mstatus(%x) priv(%x)",
                         csr[`MEPC], csr[`MSTATUS], priv);
                */
                csr[`MSTATUS][`MS_MIE] <= csr[`MSTATUS][`MS_MPIE];
                priv <= csr[`MSTATUS][`MS_MPP];

                trap_en <= `ENABLE;
                trap_pc <= csr[`MEPC];
            end else if (sys_ops.csrrw_op) begin
                //$display($time,, "csrrw: (%x,%x,%x)",
                         //sys_ops.csr_addr, csr[sys_ops.csr_addr], wdata);
                csr[sys_ops.csr_addr] <= wdata;
            end else if (sys_ops.csrrs_op) begin
                //$display($time,, "csrrs: (%x,%x,%x)",
                         //sys_ops.csr_addr, csr[sys_ops.csr_addr], wdata);
                csr[sys_ops.csr_addr] <= csr[sys_ops.csr_addr] | wdata;
            end else if (sys_ops.csrrc_op) begin
                //$display($time,, "csrrc: (%x,%x,%x)",
                         //sys_ops.csr_addr, csr[sys_ops.csr_addr], wdata);
                csr[sys_ops.csr_addr] <= csr[sys_ops.csr_addr] & ~wdata;
            end
        end

    end

endmodule
