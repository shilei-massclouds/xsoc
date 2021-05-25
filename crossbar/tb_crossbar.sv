`timescale 1ns/1ps

`include "isa.vh"
`include "addr_space.vh"

module tb_crossbar;

    wire clk;
    wire rst_n;

    tilelink master[16]();
    tilelink slave[64]();

    wire [15:0] request;
    wire [15:0] grant;

    clk_rst u_clk_rst (
        .clk   (clk   ),
        .rst_n (rst_n )
    );

    stimulator u_stimulator (
    	.clk     (clk     ),
        .rst_n   (rst_n   ),
        .request (request ),
        .grant   (grant   ),
        .master  (master  )
    );

    crossbar u_crossbar (
    	.clk     (clk     ),
        .rst_n   (rst_n   ),
        .request (request ),
        .grant   (grant   ),
        .master  (master  ),
        .slave   (slave   )
    );

    zero_page zero_page (slave[CHIP_ZERO]);

    rom u_rom (
    	.clk    (clk    ),
        .rst_n  (rst_n  ),
        .bus    (slave[CHIP_ROM])
    );

    uart u_uart (
    	.clk   (clk   ),
        .rst_n (rst_n ),
        .bus   (slave[CHIP_UART])
    );

    ram u_ram (
    	.clk   (clk   ),
        .rst_n (rst_n ),
        .bus   (slave[CHIP_RAM])
    );

    initial begin
        $fsdbDumpfile("crossbar.fsdb");
        $fsdbDumpvars();
    end

endmodule
