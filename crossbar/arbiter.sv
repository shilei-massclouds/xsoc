`timescale 1ns / 1ps

`include "isa.vh"

module arbiter (
    input  wire clk,
    input  wire rst_n,
    input  wire [15:0] request,
    output wire [15:0] grant
);

    reg [15:0] mask;

    wire [15:0] sl_mask = {mask[14:0], mask[15]};
    wire [31:0] double_req = {request, request};
    wire [31:0] double_grnt = double_req & ~(double_req - sl_mask);
    wire [15:0] next_mask = (double_grnt[31:16] | double_grnt[15:0]);

    wire valid = |next_mask;
    assign grant = valid ? next_mask : 16'b0;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            mask <= 16'b0000_0000_0000_0001;
        end else begin
            mask <= valid ? next_mask : mask;
        end
    end

endmodule
