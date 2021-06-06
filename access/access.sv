/*
 * When MA(stage) is blocked, it requires all other stages to stall,
 * including WB(stage).
 * REASON: EX(stage) may depend on forwarding reg-value from WB(stage),
 * so WB(stage) must maintain its state by stalling R-MA-WB.
 */

`timescale 1ns / 1ps

`include "isa.vh"

module access (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         clear,
    input  wire         trap_en,

    io_ops.dst          io_ops,

    input  wire [63:0]  pc,
    input  wire [4:0]   rd,

    input  wire [63:0]  result,
    input  wire [63:0]  data2,

    input  wire [63:0]  csr_data,
    input  wire         op_csr,

    input  wire         invalid,

    output wire [63:0]  ma_out,

    output wire [63:0]  pc_out,
    output wire [4:0]   rd_out,
    output wire [63:0]  data_out,

    output wire         stall,
    output wire         request,
    tilelink.master     bus
);

    wire [63:0] out;
    wire [63:0] cache_out;

    wire hit;
    wire cache_hit = io_ops.load_op & hit;
    wire update = bus.d_valid & ~bus.d_param[0];

    assign ma_out = op_csr ? csr_data :
                    hit    ? cache_out : out;

    datacache u_datacache (
        .clk         (clk         ),
        .rst_n       (rst_n       ),
        .invalid     (invalid     ),
        .pc          (pc          ),
        .io_ops      (io_ops      ),
        .addr        (result      ),
        .data        (cache_out   ),
        .hit         (hit         ),
        .update      (update      ),
        .update_data (bus.d_data  )
    );

    dataagent u_dataagent (
        .io_ops        (io_ops        ),
        .cache_hit     (cache_hit     ),
        .calc_ret      (result        ),
        .data2         (data2         ),
        .out           (out           ),
        .stall         (stall         ),
        .request       (request       ),
        .bus           (bus           )
    );

    stage_ma_wb u_stage_ma_wb (
        .clk      (clk      ),
        .rst_n    (rst_n    ),
        .clear    (clear    ),
        .stall    (stall    ),
        .trap_en  (trap_en  ),
        .pc       (pc       ),
        .rd       (rd       ),
        .data     (ma_out   ),
        .pc_out   (pc_out   ),
        .rd_out   (rd_out   ),
        .data_out (data_out )
    );

    dbg_access u_dbg_access (
        .clk    (clk    ),
        .rst_n  (rst_n  ),
        .stall  (stall  ),
        .pc     (pc     ),
        .rd     (rd     ),
        .addr   (result ),
        .data   (ma_out ),
        .request(request),
        .io_ops (io_ops ),
        .bus    (bus    )
    );

endmodule
