`timescale 1ns / 1ps

`include "isa.vh"

module dbg_execute (
    input wire clk,
    input wire rst_n,

    input wire stall,

    input wire [63:0] pc,
    input wire [4:0]  rd,
    input wire [63:0] result,
    input wire [63:0] data2,

    input wire        bj_en,
    input wire [63:0] bj_pc,

    io_ops.dst  io_ops,
    bj_ops.dst  bj_ops,
    sys_ops.dst sys_ops
);

    bit exit, pending;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            exit <= 1'b0;
            pending <= 1'b0;
        end else begin
            if (check_verbose(pc)) begin
                $display($time,, "Execute: [%08x] rd(%s) ret(%0x) data2(%0x) wfi(%0x) load/store(%0x,%0x) branch(%0x) j(%0x) stall(%0x)",
                         pc, abi_names[rd], result, data2,
                         sys_ops.wfi_op,
                         io_ops.load_op, io_ops.store_op,
                         {bj_ops.beq_op, bj_ops.bne_op,
                          bj_ops.blt_op, bj_ops.bge_op,
                          bj_ops.bltu_op, bj_ops.bgeu_op},
                         {bj_ops.jal_op, bj_ops.jalr_op},
                         stall);

                if (bj_en)
                    $display($time,, "Execute-BJ: [%08x] bj-pc(%0x)",
                             pc, bj_pc);
            end

            pending <= sys_ops.wfi_op;
            exit <= pending;

            if (exit)
                $finish();
        end
    end

endmodule
