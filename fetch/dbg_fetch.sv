`timescale 1ns / 1ps

`include "isa.vh"

module dbg_fetch (
    input wire clk,
    input wire rst_n,

    input wire [31:0] inst,
    input wire [63:0] pc,
    input wire trap_en,
    input wire bj_en,
    input wire stall,
    input wire page_fault,
    input wire invalid,
    input wire [4:0] cause,
    input wire [63:0] tval
);

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            if (check_verbose(pc)) begin
                $display($time,, "Fetch: [%08x] %x; page_fault(%0x) cause(%0x,%0x); trap_en(%0x) bj_en(%0x) stall(%0x) invalid(%0x)",
                         pc, inst, page_fault, cause, tval,
                         trap_en, bj_en, stall, invalid);
            end
        end
    end

endmodule
