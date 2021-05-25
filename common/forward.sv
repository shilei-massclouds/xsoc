`timescale 1ns / 1ps

`include "isa.vh"

module forward (
    input  wire [4:0]  rs1,
    input  wire [63:0] data1,
    input  wire [4:0]  rs2,
    input  wire [63:0] data2,
    input  wire [4:0]  ma_rd,
    input  wire [63:0] ma_out,
    input  wire [4:0]  wb_rd,
    input  wire [63:0] wb_out,

    output wire [63:0] out1,
    output wire [63:0] out2
);

    assign out1 = !rs1 ? 64'b0 :
                  (rs1 == ma_rd) ? ma_out :
                  (rs1 == wb_rd) ? wb_out : data1;

    assign out2 = !rs2 ? 64'b0 :
                  (rs2 == ma_rd) ? ma_out :
                  (rs2 == wb_rd) ? wb_out : data2;

endmodule
