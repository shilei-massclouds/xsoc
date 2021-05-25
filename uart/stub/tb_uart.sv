`timescale 1ns / 1ps

`include "isa.vh"

module tb_uart;

    wire clk;
    wire rst_n;

    tilelink bus();

    clk_rst u_clk_rst (
        .clk   (clk   ),
        .rst_n (rst_n )
    );

    stimulator u_stimulator (
        .clk    (clk  ),
        .rst_n  (rst_n),
        .bus    (bus  )
    );

    uart u_uart (
        .clk   (clk   ),
        .rst_n (rst_n ),
        .bus   (bus   )
    );

endmodule
