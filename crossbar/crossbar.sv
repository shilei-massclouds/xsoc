`timescale 1ns / 1ps

`include "isa.vh"

module crossbar (
    input   wire    clk,
    input   wire    rst_n,

    input   wire    [15:0] request,
    output  wire    [15:0] grant,

    tilelink.slave  master[16],
    tilelink.master slave[64]
);

    wire set_owner;
    wire clr_owner;

    crossbar_ctl ctl (
    	.clk       (clk       ),
        .rst_n     (rst_n     ),
        .request   (request   ),
        .grant     (grant     ),
        .set_owner (set_owner ),
        .clr_owner (clr_owner )
    );

    crossbar_dp dp (
    	.clk       (clk       ),
        .rst_n     (rst_n     ),
        .set_owner (set_owner ),
        .clr_owner (clr_owner ),
        .request   (request   ),
        .grant     (grant     ),
        .master    (master    ),
        .slave     (slave     )
    );

endmodule
