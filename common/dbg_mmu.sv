`timescale 1ns / 1ps

`include "isa.vh"

module dbg_mmu (
    input wire clk,
    input wire rst_n,

    input wire [63:0] pc,
    input wire [3:0]  state,
    input wire [3:0]  next_state,
    input wire [63:0] addr,
    input wire [63:0] pte,
    input wire        invalid,
    input wire        tlb_hit
);

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            if (check_verbose(pc)) begin
                $display($time,, "MMU: [%08x] state(%0x=>%0x) pte(%0x) addr(%0x) invalid(%0x) tlb_hit(%0x)",
                         pc, state, next_state, pte, addr, invalid, tlb_hit);
            end
        end
    end

endmodule
