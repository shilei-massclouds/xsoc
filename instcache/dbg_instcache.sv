`timescale 1ns / 1ps

`include "isa.vh"

module dbg_instcache (
    input wire clk,
    input wire rst_n,

    input wire [63:0] pc,
    input wire [1:0]  state,

    input wire [88:0] line,
    input wire [88:0] bh_line,
    input wire [1:0]  req_bmp,

    input wire inst_valid,
    input wire inst_comp,
    input wire [31:0] inst,

    input wire page_fault,
    input wire invalid,

    input wire request,
    tilelink.master bus
);

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else if (check_verbose(pc)) begin
            $display($time,, "instcache: [%0x] state(%0x) line(%0x, %0x) bus_request(%0x) req_bmp(%0x) page_fault(%0x) invalid(%0x)",
                     pc, state, line, bh_line, request, req_bmp,
                     page_fault, invalid);

            if (bus.a_valid)
                $display($time,, "instcache[addr]: [%x]", bus.a_address);

            if (bus.d_valid)
                $display($time,, "instcache[data]: %x", bus.d_data);
        end
    end

endmodule
