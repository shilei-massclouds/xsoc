`ifndef __CSR_ADDR_VH__
    `define __CSR_ADDR_VH__

`define U_MODE  2'b00
`define S_MODE  2'b01
`define M_MODE  2'b11

`define E_ECALL_U   64'h8
`define E_ECALL_S   64'h9
`define E_ECALL_M   64'hB

`define MSTATUS     'h300
`define MISA        'h301
`define MEDELEG     'h302
`define MIDELEG     'h303
`define MIE         'h304
`define MTVEC       'h305
`define MCOUNTEREN  'h306

`define MSCRATCH    'h340
`define MEPC        'h341
`define MCAUSE      'h342
`define MTVAL       'h343
`define MIP         'h344

`define PMPCFG0     'h3a0
`define PMPCFG2     'h3a2
`define PMPADDR0    'h3b0
`define PMPADDR1    'h3b1
`define PMPADDR2    'h3b2
`define PMPADDR3    'h3b3
`define PMPADDR4    'h3b4
`define PMPADDR5    'h3b5
`define PMPADDR6    'h3b6
`define PMPADDR7    'h3b7
`define PMPADDR8    'h3b8
`define PMPADDR9    'h3b9
`define PMPADDR10   'h3ba
`define PMPADDR11   'h3bb
`define PMPADDR12   'h3bc
`define PMPADDR13   'h3bd
`define PMPADDR14   'h3be
`define PMPADDR15   'h3bf

`define MVENDORID   'hf11
`define MARCHID     'hf12
`define MIMPID      'hf13
`define MHARTID     'hf14

localparam MISA_INIT_VAL = {
    2'b10,  // 63:62 MXL (XLEN = 64)
    36'b0,  // 61:26 WIRI
    1'b0,   // 25 Z Reserved
    1'b0,   // 24 Y Reserved
    1'b0,   // 23 X Non-standard extensions present
    1'b0,   // 22 W Reserved
    1'b0,   // 21 V Tentatively reserved for Vector
    1'b1,   // 20 U User mode implemented
    1'b0,   // 19 T Tentatively reserved for Transactional Memory extension
    1'b1,   // 18 S Supervisor mode implemented
    1'b0,   // 17 R Reserved
    1'b0,   // 16 Q Quad-precision floating-point extension
    1'b0,   // 15 P Tentatively reserved for Packed-SIMD extension
    1'b0,   // 14 O Reserved
    1'b0,   // 13 N User-level interrupts supported
    1'b1,   // 12 M Integer Multiply/Divide extension
    1'b0,   // 11 L Tentatively reserved for Decimal Floating-Point extension
    1'b0,   // 10 K Reserved
    1'b0,   //  9 J Reserved
    1'b1,   //  8 I RV32I/64I/128I base ISA
    1'b0,   //  7 H Hypervisor mode implemented
    1'b0,   //  6 G Additional standard extensions present
    1'b0,   //  5 F Single-precision floating-point extension
    1'b0,   //  4 E RV32E base ISA
    1'b0,   //  3 D Double-precision floating-point extension
    1'b1,   //  2 C Compressed extension
    1'b0,   //  1 B Tentatively reserved for Bit operations extension
    1'b1    //  0 A Atomic extension
};

/* MSTATUS bits */
`define MS_MIE      3
`define MS_MPIE     7
`define MS_MPP      12:11

`endif
