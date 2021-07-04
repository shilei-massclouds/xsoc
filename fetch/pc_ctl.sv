`timescale 1ns / 1ps

`include "isa.vh"

module pc_ctl (
    input   wire    clk,
    input   wire    rst_n,

    input   wire    stall,
    input   wire    trap_en,
    input   wire    [63:0] trap_pc,
    input   wire    bj_en,
    input   wire    [63:0] bj_pc,

    input   wire    inst_valid,
    input   wire    inst_comp,

    output  reg     [63:0] pc
);

    wire [63:0] next_pc = trap_en ? trap_pc :
                          bj_en ? bj_pc :
                          (stall | ~inst_valid) ? pc :
                          (inst_comp ? pc+2 : pc+4);

    always @ (posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            pc <= next_pc;
        end
    end

    initial begin
        if (getenv("RESTORE").len() > 0) begin
            pc = restore_pc();
            $display($time,, "restore: pc(%x)", pc);
        end else begin
            pc = 64'h1000;
        end
    end

endmodule
