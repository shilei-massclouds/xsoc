`timescale 1ns / 1ps

`include "isa.vh"

module regfile (
    input  wire         clk,
    input  wire         rst_n,

    input  wire [4:0]   rs1,
    output wire [63:0]  data1,
    input  wire [4:0]   rs2,
    output wire [63:0]  data2,
    input  wire [4:0]   wb_rd,
    input  wire [63:0]  wb_out
);

    bit [63:0] data[32];

    assign data1 = (rs1 == 5'b0) ? 64'b0 :
                   (rs1 == wb_rd) ? wb_out : data[rs1];

    assign data2 = (rs2 == 5'b0) ? 64'b0 :
                   (rs2 == wb_rd) ? wb_out : data[rs2];

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            if (wb_rd) data[wb_rd] <= wb_out;
        end
    end

    initial begin
        if (getenv("RESTORE").len() > 0)
            restore_reg(data);
    end

endmodule
