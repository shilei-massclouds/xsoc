`timescale 1ns / 1ps

`include "isa.vh"

module dataagent (
    io_ops.dst          io_ops,

    input  wire         cache_hit,

    input  wire [63:0]  calc_ret,
    input  wire [63:0]  data2,


    output wire [63:0]  out,

    output wire         stall,
    output wire         request,
    tilelink.master     bus
);

    wire [7:0]  size_mask = {{4{io_ops.size[1] & io_ops.size[0]}},
                             {2{io_ops.size[1]}},
                             {io_ops.size[1] | io_ops.size[0]}, 1'b1};

    wire [2:0]  offset = bus.d_param[0] ? 3'b0 : calc_ret[2:0];
    wire [7:0]  byte_mask = (io_ops.mask & size_mask) << offset;
    wire [63:0] mask = {{8{byte_mask[7]}}, {8{byte_mask[6]}},
                        {8{byte_mask[5]}}, {8{byte_mask[4]}},
                        {8{byte_mask[3]}}, {8{byte_mask[2]}},
                        {8{byte_mask[1]}}, {8{byte_mask[0]}}};

    wire [63:0] data = bus.d_valid ?
                       ((bus.d_data & mask) >> (8 * offset)) : 64'b0;

    wire [2:0]  size = bus.d_size;
    wire [63:0] _out = ~size[2] ?
               ({64{(~size[1] & ~size[0])}} & {{56{data[7]}}, data[7:0]} |
                {64{(~size[1] & size[0])}} & {{48{data[15]}}, data[15:0]} |
                {64{(size[1] & ~size[0])}} & {{32{data[31]}}, data[31:0]} |
                {64{size[1] & size[0]}} & data) :
               data;

    wire amo_arith = io_ops.amo_add_op |
                     io_ops.amo_min_op | io_ops.amo_max_op |
                     io_ops.amo_minu_op | io_ops.amo_maxu_op;

    wire amo_logic = io_ops.amo_xor_op | io_ops.amo_or_op |
                     io_ops.amo_and_op | io_ops.amo_swap_op;

    wire load   = io_ops.load_op | io_ops.lr_op;
    wire store  = io_ops.store_op | io_ops.sc_op;
    wire ma_op  = (io_ops.load_op & ~cache_hit) |
                  io_ops.lr_op | store | amo_arith | amo_logic;

    assign request = ma_op;

    assign stall = ma_op & ~bus.d_valid;
    assign out = ma_op ? _out : calc_ret;

    assign bus.a_address = calc_ret;
    assign bus.a_data = data2;
    assign bus.a_valid = ma_op;

    assign bus.d_ready = `ENABLE;
    assign bus.a_size = io_ops.size;
    assign bus.a_mask = io_ops.mask;
    assign bus.a_source = 4'b0000;
    assign bus.a_corrupt = io_ops.lr_op | io_ops.sc_op;

    assign bus.a_opcode = ({3{load}} & `TL_GET) | ({3{store}} & `TL_PUT_F) |
                          ({3{amo_arith}} & `TL_ARITH_DATA) |
                          ({3{amo_logic}} & `TL_LOGIC_DATA);

    assign bus.a_param = ({3{io_ops.amo_add_op}} & `TL_PARAM_ADD) |
                         ({3{io_ops.amo_min_op}} & `TL_PARAM_MIN) |
                         ({3{io_ops.amo_max_op}} & `TL_PARAM_MAX) |
                         ({3{io_ops.amo_minu_op}} & `TL_PARAM_MINU) |
                         ({3{io_ops.amo_maxu_op}} & `TL_PARAM_MAXU) |
                         ({3{io_ops.amo_xor_op}} & `TL_PARAM_XOR) |
                         ({3{io_ops.amo_or_op}} & `TL_PARAM_OR) |
                         ({3{io_ops.amo_and_op}} & `TL_PARAM_AND) |
                         ({3{io_ops.amo_swap_op}} & `TL_PARAM_SWAP);

endmodule
