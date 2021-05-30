`timescale 1ns / 1ps

`include "isa.vh"

module dbg_decode (
    input wire clk,
    input wire rst_n,

    input wire [63:0]   pc,
    input wire [31:0]   inst,
    input wire [4:0]    rd,
    input wire [63:0]   data1,
    input wire [63:0]   data2,
    input wire [63:0]   imm,
    input wire          with_imm,
    input wire [4:0]    cause,
    input wire [63:0]   tval
);

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            if (check_verbose(pc)) begin
                $display($time,, "Decode: [%08x] inst(%0x) rd(%0x) data(%0x, %0x) imm(%0x:%0x) cause(%0x,%0x)",
                         pc, inst, rd, data1, data2, imm, with_imm,
                         cause, tval);
            end
        end
    end

endmodule
