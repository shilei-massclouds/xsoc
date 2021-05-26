`timescale 1ns / 1ps

`include "isa.vh"

module stage_ma_wb (
    input  wire clk,
    input  wire rst_n,
    input  wire clear,
    input  wire stall,
    input  wire trap_en,

    input  wire [`XMSB:0]   pc,
    input  wire [4:0]       rd,
    input  wire [63:0]      data,

    output wire [`XMSB:0]   pc_out,
    output wire [4:0]       rd_out,
    output wire [63:0]      data_out
);

    dff #(133, 133'b0) dff_stage (
        .clk    (clk),
        .rst_n  (rst_n),
        .clear  (clear | (trap_en & ~stall)),
        .stall  (stall),
        .d      ({pc, rd, data}),
        .q      ({pc_out, rd_out, data_out})
    );

endmodule
