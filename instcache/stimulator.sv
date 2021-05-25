`timescale 1ns / 1ps

`include "isa.vh"

module stimulator (
    input   wire clk,
    input   wire rst_n,

    output  reg  [63:0] pc,

    input   wire inst_valid,
    input   wire inst_comp,
    input   wire [31:0] inst,

    input   wire request
);

    wire [63:0] next_pc;

    assign next_pc = inst_valid ? (pc + (inst_comp ? 2 : 4)) : pc;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            pc <= 64'h000;
        end else begin
            pc <= next_pc;
        end
    end

endmodule
