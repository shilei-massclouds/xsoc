`timescale 1ns / 1ps

`include "isa.vh"

module rom_front (
    input  wire clk,
    input  wire rst_n,

    /* TileLink Side */
    tilelink.slave bus,

    /* Fifo Side */
    input  wire almost_full,
    output wire wr_en,
    output wire [7:0] dout,

    input  wire almost_empty,
    output wire rd_en,
    input  wire [7:0] din
);

    assign bus.d_opcode  = `TL_ACCESS_ACK_DATA;
    assign bus.d_param   = 2'b0;
    assign bus.d_sink    = 6'b0;
    assign bus.d_corrupt = `FALSE;
    assign bus.d_denied  = `FALSE;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            bus.d_size   <= 3'b0;
            bus.d_source <= 4'b0;
        end else begin
            if (bus.a_valid & bus.a_ready) begin
                bus.d_size   <= bus.a_size;
                bus.d_source <= bus.a_source;
            end
        end
    end

    rom_wr u_rom_wr (
    	.clk         (clk         ),
        .rst_n       (rst_n       ),
        .valid       (bus.a_valid ),
        .ready       (bus.a_ready ),
        .addr        (bus.a_address),
        .almost_full (almost_full ),
        .wr_en       (wr_en       ),
        .dout        (dout        )
    );

    rom_rd u_rom_rd (
    	.clk          (clk          ),
        .rst_n        (rst_n        ),
        .valid        (bus.d_valid  ),
        .data         (bus.d_data   ),
        .ready        (bus.d_ready  ),
        .almost_empty (almost_empty ),
        .rd_en        (rd_en        ),
        .din          (din          )
    );

endmodule