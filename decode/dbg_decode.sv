`timescale 1ns / 1ps

`include "isa.vh"

module dbg_decode (
    input wire clk,
    input wire rst_n,

    input wire [63:0]   pc,
    input wire [63:0]   data1,
    input wire [63:0]   data2,
    input wire [63:0]   imm,
    input wire          with_imm
);

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            if (check_verbose(pc)) begin
                $display($time,, "Decode: [%08x] data(%0x, %0x) imm(%0x:%0x)",
                         pc, data1, data2, imm, with_imm);
            end
        end
    end

endmodule
