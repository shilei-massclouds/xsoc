`timescale 1ns / 1ps

`include "isa.vh"
`include "addr_space.vh"

struct {
    bit[63:0] start;
    bit[63:0] size;
} ranges[CHIP_LAST] = '{
    '{'h0000000000000000, 'h0000000000001000},   /* ZERO-Page */
    '{'h0000000000001000, 'h000000000ffff000},   /* ROM */
    '{'h0000000010000000, 'h0000000000000100},   /* UART */
    '{'h0000000010001000, 'h0000000000001000},   /* MMIO-BLK */
    '{'h0000000080000000, 'h0000000080000000}    /* RAM */
};

`define IN_CHIP_RANGE(_addr, _chip) \
    (((_addr >= ranges[_chip].start) && \
      (_addr < (ranges[_chip].start + ranges[_chip].size))) ? _chip : 0)

module pma (
    input wire [63:0]   a_address,

    output wire [5:0]   chip_sel,
    output wire [63:0]  chip_addr
);

    assign chip_sel = `IN_CHIP_RANGE(a_address, CHIP_ZERO) |
                      `IN_CHIP_RANGE(a_address, CHIP_ROM) |
                      `IN_CHIP_RANGE(a_address, CHIP_UART) |
                      `IN_CHIP_RANGE(a_address, CHIP_MMIO_BLK) |
                      `IN_CHIP_RANGE(a_address, CHIP_RAM);

    assign chip_addr = a_address - ranges[chip_sel].start;

endmodule