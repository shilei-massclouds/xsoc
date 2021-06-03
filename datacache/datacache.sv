`timescale 1ns / 1ps

`include "isa.vh"

module datacache (
    input   wire    clk,
    input   wire    rst_n,

    input   wire    invalid,

    input   wire    [63:0] pc,

    io_ops.dst      io_ops,
    input   wire    [63:0] addr,
    output  wire    [63:0] data,
    output  wire    hit,

    input   wire    update,
    input   wire    [2:0] opcode,
    input   wire    [63:0] update_data
);

    /*
     * Address space of data:
     * ADDR := {tag(56), index(5), offset(3)};
     */
    wire [55:0] tag    = addr[63:8];
    wire [4:0]  index  = addr[7:3];
    wire [2:0]  offset = addr[2:0];

    /*
     * Internal cache line:
     * Fields := {valid(1), tag(56), data(64)};
     */
    `define F_D_DATA  63:0
    `define F_D_TAG   119:64
    `define F_D_VALID 120

    localparam CACHE_WIDTH = 1 + 56 + 64;   /* bits */
    localparam CACHE_DEPTH = 32;            /* index: 2^5 */

    bit [(CACHE_WIDTH-1):0] lines[CACHE_DEPTH];

    wire [63:0] _data = lines[index][`F_D_DATA];

    wire [7:0] size_mask = {{4{io_ops.size[1] & io_ops.size[0]}},
                            {2{io_ops.size[1]}},
                            {io_ops.size[1] | io_ops.size[0]}, 1'b1};
    wire [7:0] byte_mask = (io_ops.mask & size_mask) << offset;
    wire [63:0] mask = {{8{byte_mask[7]}}, {8{byte_mask[6]}},
                        {8{byte_mask[5]}}, {8{byte_mask[4]}},
                        {8{byte_mask[3]}}, {8{byte_mask[2]}},
                        {8{byte_mask[1]}}, {8{byte_mask[0]}}};

    /* Output */
    assign hit = io_ops.load_op &
                 lines[index][`F_D_VALID] & (lines[index][`F_D_TAG] == tag);

    wire [63:0] _tmp = hit ? ((_data & mask) >> (offset * 8)) : 64'b0;
    wire [2:0]  size = io_ops.size;

    assign data = ~size[2] ?
               ({64{(~size[1] & ~size[0])}} & {{56{_tmp[7]}}, _tmp[7:0]} |
                {64{(~size[1] & size[0])}} & {{48{_tmp[15]}}, _tmp[15:0]} |
                {64{(size[1] & ~size[0])}} & {{32{_tmp[31]}}, _tmp[31:0]} |
                {64{size[1] & size[0]}} & _tmp) :
               _tmp;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            if (invalid) begin
                for (integer i = 0; i < CACHE_DEPTH; i++) begin
                    lines[i] <= {CACHE_WIDTH{1'b0}};
                end
            end

            if (update) begin
                if (opcode == `TL_ACCESS_ACK_DATA)
                    lines[index] <= {1'b1, tag, update_data};
                else
                    lines[index] <= 64'b0;
            end
        end
    end

    dbg_datacache u_dbg_datacache (
        .clk     (clk           ),
        .rst_n   (rst_n         ),
        .pc      (pc            ),
        .line    (lines[index]  ),
        .hit     (hit           ),
        .data    (data          ),
        .update  (update        ),
        .update_data(update_data)
    );

endmodule
