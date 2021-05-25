`timescale 1ns / 1ps

`include "isa.vh"

module dbg_crossbar_dp (
    input wire clk,
    input wire rst_n,

    input wire [2:0]    a_opcode,
    input wire [2:0]    a_param,
    input wire [2:0]    a_size,
    input wire [3:0]    a_source,
    input wire [63:0]   a_address,
    input wire [7:0]    a_mask,
    input wire [63:0]   a_data,
    input wire          a_corrupt,
    input wire          a_valid,
    input wire          a_ready,
    input wire [5:0]    chip_sel,
    input wire [63:0]   chip_addr
);

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            if (check_verbose(64'b0)) begin
                if (a_valid) begin
                    $display($time,, "Crossbar-dp: a_addr[%08x] chip(%0x : %0x)",
                             a_address, chip_sel, chip_addr);
                end
            end
        end
    end

endmodule
