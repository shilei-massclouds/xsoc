`timescale 1ns / 1ps

module fpga_rom_test (
    input  wire clk,
    input  wire ft_clk,
    input  wire rst_n,

    input  wire rxf_n,
    input  wire txe_n,
    output wire oe_n,
    output wire rd_n,
    output wire wr_n,
    output wire siwu_n,

    inout  wire [7:0] adbus
);

    wire [7:0] ftdi_in;
    reg  [7:0] cmd_data_in;
    wire [7:0] cmd_data_out;
    reg  cmd_wr_en;
    wire cmd_rd_en;
    wire cmd_almost_full;
    wire cmd_almost_empty;

    wire [7:0] ftdi_out;
    wire [7:0] res_data_in;
    wire [7:0] res_data_out;
    wire res_wr_en;
    reg  res_rd_en;
    wire res_almost_full;
    wire res_almost_empty;

    tilelink bus();

    assign adbus = ftdi_in;
    assign ftdi_out = adbus;

    ftdi_wr u_ftdi_wr (
        .clk    (ft_clk),
        .rst_n  (rst_n ),
        .txe_n  (txe_n ),
        .wr_n   (wr_n  ),
        .siwu_n (siwu_n),
        .din    (cmd_data_out),
        .empty  (cmd_almost_empty),
        .rd_en  (cmd_rd_en),
        .dout   (ftdi_in)
    );

    ftdi_rd u_ftdi_rd (
        .clk   (ft_clk),
        .rst_n (rst_n ),
        .rxf_n (rxf_n ),
        .oe_n  (oe_n  ),
        .rd_n  (rd_n  ),
        .din   (ftdi_out),
        .full  (res_almost_full),
        .wr_en (res_wr_en),
        .dout  (res_data_in)
    );

    fifo cmd_fifo (
        .wr_clk(clk),
        .rd_clk(ft_clk),
        .wr_en(cmd_wr_en),
        .din(cmd_data_in),
        .rd_en(cmd_rd_en),
        .dout(cmd_data_out),
        .almost_full(cmd_almost_full),
        .almost_empty(cmd_almost_empty)
    );

    fifo res_fifo (
        .wr_clk(ft_clk),
        .rd_clk(clk),
        .wr_en(res_wr_en),
        .din(res_data_in),
        .rd_en(res_rd_en),
        .dout(res_data_out),
        .almost_full(res_almost_full),
        .almost_empty(res_almost_empty)
    );

    rom_front u_rom_front (
        .clk          (clk             ),
        .rst_n        (rst_n           ),
        .bus          (bus             ),
        .almost_full  (cmd_almost_full ),
        .wr_en        (cmd_wr_en       ),
        .dout         (cmd_data_in     ),
        .almost_empty (res_almost_empty),
        .rd_en        (res_rd_en       ),
        .din          (res_data_out    )
    );

    stimulator u_stimulator (
        .clk   (clk   ),
        .rst_n (rst_n ),
        .bus   (bus)
    );

    ila ila (
        .clk(clk),                  // input wire clk
        .probe0(bus.d_valid),       // input wire [0:0]  probe0
        .probe1(bus.d_data),        // input wire [63:0] probe1
        .probe2(cmd_almost_full),   // input wire [0:0]  probe2
        .probe3(cmd_data_in)        // input wire [7:0]  probe3
    );

endmodule
