`timescale 1ns / 1ps

`include "isa.vh"

module stage_ex_ma (
    input  wire clk,
    input  wire rst_n,
    input  wire clear,
    input  wire stall,
    input  wire trap_en,

    input  wire [`XMSB:0]   pc_in,
    input  wire [4:0]       rd_in,
    input  wire [63:0]      result_in,
    input  wire [63:0]      data1_in,
    input  wire [63:0]      data2_in,
    input  wire [4:0]       cause_in,
    input  wire [63:0]      tval_in,
    io_ops.dst              io_ops_in,

    output wire [`XMSB:0]   pc_out,
    output wire [4:0]       rd_out,
    output wire [63:0]      result_out,
    output wire [63:0]      data1_out,
    output wire [63:0]      data2_out,
    input  wire [4:0]       cause_out,
    input  wire [63:0]      tval_out,
    io_ops.src              io_ops_out
);

    wire [23:0] io_bits_out;
    wire [23:0] io_bits_in = {io_ops_in.load_op, io_ops_in.store_op,
                              io_ops_in.amo_add_op, io_ops_in.amo_swap_op,
                              io_ops_in.lr_op, io_ops_in.sc_op,
                              io_ops_in.amo_xor_op, io_ops_in.amo_or_op,
                              io_ops_in.amo_and_op, io_ops_in.amo_min_op,
                              io_ops_in.amo_max_op, io_ops_in.amo_minu_op,
                              io_ops_in.amo_maxu_op,
                              io_ops_in.size, io_ops_in.mask};

    dff #(354, 354'b0) dff_stage (
        .clk    (clk),
        .rst_n  (rst_n),
        //.clear  (clear | (trap_en & ~stall)),
        .clear  (clear | trap_en),
        .stall  (stall),
        .d      ({pc_in, rd_in, result_in, data1_in, data2_in,
                  cause_in, tval_in, io_bits_in}),
        .q      ({pc_out, rd_out, result_out, data1_out, data2_out,
                  cause_out, tval_out, io_bits_out})
    );

    assign {io_ops_out.load_op, io_ops_out.store_op,
            io_ops_out.amo_add_op, io_ops_out.amo_swap_op,
            io_ops_out.lr_op, io_ops_out.sc_op,
            io_ops_out.amo_xor_op, io_ops_out.amo_or_op,
            io_ops_out.amo_and_op, io_ops_out.amo_min_op,
            io_ops_out.amo_max_op, io_ops_out.amo_minu_op,
            io_ops_out.amo_maxu_op,
            io_ops_out.size, io_ops_out.mask} = io_bits_out;

endmodule
