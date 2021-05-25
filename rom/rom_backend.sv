`timescale 1ns / 1ps

`include "isa.vh"

module rom_backend (
    input  wire clk,
    input  wire rst_n,

    output wire almost_full,
    input  wire wr_en,
    input  wire [7:0] din,

    output wire almost_empty,
    input  wire rd_en,
    output reg  [7:0] dout
);

    reg [7:0] buffer;
    reg buf_valid;

    reg lock;

    assign almost_full  = ~lock | buf_valid;
    assign almost_empty = ~lock | ~buf_valid;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            buffer <= 8'b0;
            buf_valid <= `FALSE;
            lock <= `FALSE;
        end else begin
            lock <= ~lock;

            if (wr_en) begin
                buffer <= din;
                buf_valid <= `TRUE;
            end

            if (rd_en) begin
                dout <= buffer;
                buffer <= 8'b0;
                buf_valid <= `FALSE;
            end
        end
    end

endmodule
