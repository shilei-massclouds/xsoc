/*
 * [(memory) access]
 * ex_ma -- access -- bus -- ram
 *             |
 *    forward -+- ma_wb
 */

`timescale 1ns / 1ps

`include "isa.vh"

module tb_access;

    wire clk;
    wire rst_n;
    wire stall;

    reg [4:0]  rd;
    reg [63:0] result;
    reg [63:0] data2;

    wire [4:0]  rd_out;
    wire [63:0] ma_data;
    wire [63:0] pc_out;
    wire [63:0] data_out;

    wire [63:0] pc = 64'h400;

    io_ops io_ops();
    tilelink bus();

    clk_rst u_clk_rst (
        .clk   (clk   ),
        .rst_n (rst_n )
    );

    stimulator u_stimulator (
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .clear      (clear  ),
        .stall      (stall  ),
        .io_ops     (io_ops ),
        .rd_out     (rd     ),
        .result_out (result ),
        .data2_out  (data2  )
    );

    access u_access (
        .clk      (clk      ),
        .rst_n    (rst_n    ),
        .clear    (clear    ),
        .io_ops   (io_ops   ),
        .pc       (pc       ),
        .rd       (rd       ),
        .result   (result   ),
        .data2    (data2    ),
        .ma_data  (ma_data  ),
        .pc_out   (pc_out   ),
        .rd_out   (rd_out   ),
        .data_out (data_out ),
        .stall    (stall    ),
        .request  (request  ),
        .bus      (bus      )
    );

    ram u_ram (
        .clk   (clk   ),
        .rst_n (rst_n ),
        .bus   (bus   )
    );

    initial begin
        $monitor($time,, "rd(%x) data(%x)", rd_out, data_out);

        #1024 $finish();
    end

endmodule
