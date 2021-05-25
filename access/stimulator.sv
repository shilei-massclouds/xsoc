`timescale 1ns / 1ps

`include "isa.vh"

module stimulator (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         stall,

    io_ops.src          io_ops,

    output wire         clear,
    output reg  [4:0]   rd_out,
    output reg  [63:0]  result_out,
    output reg  [63:0]  data2_out
);

    reg load_op[4] = {`DISABLE, `DISABLE, `ENABLE, `DISABLE};
    reg store_op[4] = {`DISABLE, `ENABLE, `DISABLE, `DISABLE};
    reg [4:0] rd[4] = {5'h3, 5'h0, 5'h5, 5'h6};
    reg [63:0] data2[4] = {64'h1111, 64'h2222, 64'h3333, 64'h4444};
    reg [63:0] out[4] = {64'h100, 64'h108, 64'h108, 64'h116};

    assign clear = `DISABLE;

    integer i = 0;
    always @(posedge clk) begin
        if (~rst_n) begin
            io_ops.load_op <= `DISABLE;
            io_ops.store_op <= `DISABLE;
            rd_out <= 5'b0;
            data2_out <= 64'b0;
            result_out <= 64'b0;
        end if (~stall) begin
            io_ops.load_op <= load_op[i];
            io_ops.store_op <= store_op[i];
            rd_out <= rd[i];
            data2_out <= data2[i];
            result_out <= out[i];
            i <= i + 1;
        end
    end

endmodule
