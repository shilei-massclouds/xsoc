`timescale 1ns / 1ps

`include "csr.vh"

`define ASSIGN_BUS(to, from, prop) \
    assign to.prop = paging ? prop : from.prop

module mmu (
    input  wire         clk,
    input  wire         rst_n,

    input  wire [63:0]  satp,

    tilelink.slave      virt_bus,
    tilelink.master     phy_bus
);

    reg [2:0]     a_opcode;
    reg [2:0]     a_param;
    reg [2:0]     a_size;
    reg [3:0]     a_source;
    reg [63:0]    a_address;
    reg [7:0]     a_mask;
    reg [63:0]    a_data;
    reg           a_corrupt;
    reg           a_valid;
    reg           a_ready;

    reg [2:0]     d_opcode;
    reg [1:0]     d_param;
    reg [2:0]     d_size;
    reg [3:0]     d_source;
    reg [5:0]     d_sink;
    reg           d_denied;
    reg [63:0]    d_data;
    reg           d_corrupt;
    reg           d_valid;
    reg           d_ready;

    wire paging = ~(satp[63:60] == 4'h0);

    `ASSIGN_BUS(phy_bus, virt_bus, a_opcode);
    `ASSIGN_BUS(phy_bus, virt_bus, a_param);
    `ASSIGN_BUS(phy_bus, virt_bus, a_size);
    `ASSIGN_BUS(phy_bus, virt_bus, a_source);
    `ASSIGN_BUS(phy_bus, virt_bus, a_address);
    `ASSIGN_BUS(phy_bus, virt_bus, a_mask);
    `ASSIGN_BUS(phy_bus, virt_bus, a_data);
    `ASSIGN_BUS(phy_bus, virt_bus, a_corrupt);
    `ASSIGN_BUS(phy_bus, virt_bus, a_valid);
    `ASSIGN_BUS(phy_bus, virt_bus, d_ready);

    `ASSIGN_BUS(virt_bus, phy_bus, d_opcode);
    `ASSIGN_BUS(virt_bus, phy_bus, d_param);
    `ASSIGN_BUS(virt_bus, phy_bus, d_size);
    `ASSIGN_BUS(virt_bus, phy_bus, d_source);
    `ASSIGN_BUS(virt_bus, phy_bus, d_sink);
    `ASSIGN_BUS(virt_bus, phy_bus, d_denied);
    `ASSIGN_BUS(virt_bus, phy_bus, d_data);
    `ASSIGN_BUS(virt_bus, phy_bus, d_corrupt);
    `ASSIGN_BUS(virt_bus, phy_bus, d_valid);
    `ASSIGN_BUS(virt_bus, phy_bus, a_ready);

endmodule
