/* Top module: soc */

`timescale 1ns / 1ps

`include "isa.vh"

module soc;

    wire clk;
    wire rst_n;

    wire clear = `DISABLE;

    wire [15:0] grant;
    wire [15:0] request;
    wire if_request;
    wire ma_request;

    tilelink master[16]();
    tilelink slave[64]();

    assign request[0] = if_request;
    assign request[1] = ma_request;

    clk_rst u_clk_rst (
        .clk   (clk   ),
        .rst_n (rst_n )
    );

    crossbar u_crossbar (
        .clk     (clk     ),
        .rst_n   (rst_n   ),
        .request (request ),
        .grant   (grant   ),
        .master  (master  ),
        .slave   (slave   )
    );

    cpu u_cpu (
        .clk        (clk        ),
        .rst_n      (rst_n      ),
        .clear      (clear      ),
        .if_request (if_request ),
        .if_phy_bus (master[0]  ),
        .ma_request (ma_request ),
        .ma_phy_bus (master[1]  )
    );

    zero_page zero_page(slave[0]);
    rom rom(clk, rst_n, slave[1]);
    uart uart(clk, rst_n, slave[2]);
    mmio_blk mmio_blk(clk, rst_n, slave[3]);
    ram ram(clk, rst_n, slave[4]);

    generate
        for (genvar i = 2; i < 16; i++) begin: cycle0
            assign request[i] = `DISABLE;
        end
    endgenerate

//`define DUMP_VARS
`ifdef DUMP_VARS
    initial begin
        $fsdbDumpfile("soc.fsdb");
        $fsdbDumpvars();
    end
`endif

endmodule
