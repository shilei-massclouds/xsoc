`timescale 1ns / 1ps

`include "isa.vh"

module dbg_csr (
    input wire clk,
    input wire rst_n,

    input wire [63:0] pc,
    input wire except,
    input wire medeleg,
    input wire [63:0] tvec
);

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            if (check_verbose(pc)) begin
                $display($time,, "CSR: [%08x] except(%0x) medeleg(%0x) tvec(%0x)",
                         pc, except, medeleg, tvec);
            end
        end
    end

endmodule
