`timescale 1ns / 1ps

`include "isa.vh"

module dbg_fetch (
    input wire clk,
    input wire rst_n,

    input wire [31:0] inst,
    input wire [63:0] pc
);

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            if (check_verbose(pc)) begin
                $display($time,, "Fetch: [%08x] %x", pc, inst);
            end
        end
    end

endmodule
