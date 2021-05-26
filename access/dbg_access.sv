`timescale 1ns / 1ps

`include "isa.vh"

module dbg_access (
    input wire clk,
    input wire rst_n,

    input wire stall,

    input wire [63:0] pc,
    input wire [4:0]  rd,
    input wire [63:0] addr,
    input wire [63:0] data,
    input wire request,

    input wire [63:0] trap_pc,
    input wire        trap_en,

    io_ops.dst      io_ops,
    tilelink.master bus
);

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            if (check_verbose(pc)) begin
                $display($time,, "Access: [%08x] rd(%s) addr(%0x) data(%0x) stall(%0x) d_valid(%0x:%0x) req(%0x) io_ops(%0x,%0x) param(%0x)",
                         pc, abi_names[rd], addr, data, stall,
                         bus.d_valid, bus.d_data, request,
                         io_ops.size, io_ops.mask, bus.d_param);

                if (trap_en)
                    $display($time,, "Access-Trap: [%08x] trap-pc(%0x)",
                             pc, trap_pc);
            end
        end
    end

endmodule
