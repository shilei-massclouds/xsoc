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

    rom_front u_rom_front (
        .clk          (clk             ),
        .rst_n        (rst_n           ),
        .bus          (bus             ),
        .almost_full  (cmd_almost_full ),
        .wr_en        (cmd_wr_en       ),
        .dout         (cmd_din         ),
        .almost_empty (res_almost_empty),
        .rd_en        (res_rd_en       ),
        .din          (res_dout        )
    );

    rom_backend u_rom_backend (
        .clk          (clk             ),
        .rst_n        (rst_n           ),
        .almost_full  (cmd_almost_full ),
        .wr_en        (cmd_wr_en       ),
        .din          (cmd_din         ),
        .almost_empty (res_almost_empty),
        .rd_en        (res_rd_en       ),
        .dout         (res_dout        )
    );

    initial begin
        $monitor($time,, "%x, %x", bus.d_data, bus.d_valid);
        #20480 $finish();
    end

endmodule
