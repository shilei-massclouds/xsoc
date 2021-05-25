`timescale 1ns / 1ps

`include "isa.vh"

module dbg_rom (
    input wire clk,
    input wire rst_n,

    input wire valid,
    input wire [63:0] data
);

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            if (`CHECK_ENV("VERBOSE_ROM") & valid)
                $display($time,, "ROM: %x", data);
        end
    end

endmodule
