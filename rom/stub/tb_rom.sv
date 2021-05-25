`timescale 1ns/1ps

`include "isa.vh"

module tb_rom;

    wire clk;
    wire rst_n;

    tilelink bus();

    wire cmd_almost_full;
    wire cmd_wr_en;
    wire [7:0] cmd_din;

    wire res_almost_empty;
    wire res_rd_en;
    wire [7:0] res_dout;

    clk_rst u_clk_rst (
        .clk   (clk   ),
        .rst_n (rst_n )
    );

    stimulator u_stimulator (
        .clk    (clk  ),
        .rst_n  (rst_n),
        .bus    (bus  )
    );

    rom u_rom (
        .clk   (clk   ),
        .rst_n (rst_n ),
        .bus   (bus   )
    );

    assert_rom u_assert_rom (
        .clk   (clk   ),
        .rst_n (rst_n ),
        .bus   (bus   )
    );

endmodule
