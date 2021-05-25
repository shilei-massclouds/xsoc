`timescale 1ns / 1ps

`include "isa.vh"

`define A_CHANNEL(role, id) \
    {role[id].a_opcode, role[id].a_param, role[id].a_size,\
     role[id].a_source, role[id].a_address, role[id].a_mask,\
     role[id].a_data, role[id].a_corrupt, role[id].a_valid,\
     role[id].d_ready}

`define D_CHANNEL(role, id) \
    {role[id].d_opcode, role[id].d_param, role[id].d_size,\
     role[id].d_source, role[id].d_sink, role[id].d_denied,\
     role[id].d_data, role[id].d_corrupt, role[id].d_valid,\
     role[id].a_ready}

`define MASTER_IN(id) `D_CHANNEL(master, id)

`define MASTER_OUT(id) \
    (`A_CHANNEL(master, id) & {152{owner_valid & owner_bitmap[id]}})

`define SLAVE_IN(id) `A_CHANNEL(slave, id)

`define SLAVE_OUT(id) \
    (`D_CHANNEL(slave, id) & {86{owner_valid & (chip_sel == id)}})

module crossbar_dp (
    input   wire    clk,
    input   wire    rst_n,

    input   wire    set_owner,
    input   wire    clr_owner,

    input   wire    [15:0] request,
    output  wire    [15:0] grant,

    tilelink.slave  master[16],
    tilelink.master slave[64]
);

    wire [5:0]  chip_sel;
    wire [63:0] chip_addr;

    wire [2:0]     a_opcode;
    wire [2:0]     a_param;
    wire [2:0]     a_size;
    wire [3:0]     a_source;
    wire [63:0]    a_address;
    wire [7:0]     a_mask;
    wire [63:0]    a_data;
    wire           a_corrupt;
    wire           a_valid;
    wire           a_ready;

    wire [2:0]     d_opcode;
    wire [1:0]     d_param;
    wire [2:0]     d_size;
    wire [3:0]     d_source;
    wire [5:0]     d_sink;
    wire           d_denied;
    wire [63:0]    d_data;
    wire           d_corrupt;
    wire           d_valid;
    wire           d_ready;

    reg [15:0] owner_bitmap;
    reg owner_valid;

    wire [15:0] abt_request = set_owner ? request : 16'b0;
    wire [15:0] abt_grant;

    arbiter u_arbiter (
        .clk     (clk         ),
        .rst_n   (rst_n       ),
        .request (abt_request ),
        .grant   (abt_grant   )
    );

    pma u_pma (
        .a_address (a_address ),
        .chip_sel  (chip_sel  ),
        .chip_addr (chip_addr )
    );

    assign grant = owner_bitmap;

    assign {a_opcode, a_param, a_size, a_source, a_address,
            a_mask, a_data, a_corrupt, a_valid, d_ready} =
        `MASTER_OUT(0)  | `MASTER_OUT(1)  | `MASTER_OUT(2)  | `MASTER_OUT(3)  |
        `MASTER_OUT(4)  | `MASTER_OUT(5)  | `MASTER_OUT(6)  | `MASTER_OUT(7)  |
        `MASTER_OUT(8)  | `MASTER_OUT(9)  | `MASTER_OUT(10) | `MASTER_OUT(11) |
        `MASTER_OUT(12) | `MASTER_OUT(13) | `MASTER_OUT(14) | `MASTER_OUT(15);

    generate
        for (genvar j = 0; j < 64; j++) begin
            assign `SLAVE_IN(j) = {
                a_opcode, a_param, a_size, a_source, chip_addr,
                a_mask, a_data, a_corrupt, a_valid, d_ready
            } & {152{owner_valid & (chip_sel == j)}};
        end
    endgenerate

    assign {d_opcode, d_param, d_size, d_source, d_sink,
            d_denied, d_data, d_corrupt, d_valid, a_ready} =
        `SLAVE_OUT(0)  | `SLAVE_OUT(1)  | `SLAVE_OUT(2)  | `SLAVE_OUT(3)  |
        `SLAVE_OUT(4)  | `SLAVE_OUT(5)  | `SLAVE_OUT(6)  | `SLAVE_OUT(7)  |
        `SLAVE_OUT(8)  | `SLAVE_OUT(9)  | `SLAVE_OUT(10) | `SLAVE_OUT(11) |
        `SLAVE_OUT(12) | `SLAVE_OUT(13) | `SLAVE_OUT(14) | `SLAVE_OUT(15) |
        `SLAVE_OUT(16) | `SLAVE_OUT(17) | `SLAVE_OUT(18) | `SLAVE_OUT(19) |
        `SLAVE_OUT(20) | `SLAVE_OUT(21) | `SLAVE_OUT(22) | `SLAVE_OUT(23) |
        `SLAVE_OUT(24) | `SLAVE_OUT(25) | `SLAVE_OUT(26) | `SLAVE_OUT(27) | `SLAVE_OUT(28) | `SLAVE_OUT(29) | `SLAVE_OUT(30) | `SLAVE_OUT(31) |
        `SLAVE_OUT(32) | `SLAVE_OUT(33) | `SLAVE_OUT(34) | `SLAVE_OUT(35) |
        `SLAVE_OUT(36) | `SLAVE_OUT(37) | `SLAVE_OUT(38) | `SLAVE_OUT(39) |
        `SLAVE_OUT(40) | `SLAVE_OUT(41) | `SLAVE_OUT(42) | `SLAVE_OUT(43) |
        `SLAVE_OUT(44) | `SLAVE_OUT(45) | `SLAVE_OUT(46) | `SLAVE_OUT(47) |
        `SLAVE_OUT(48) | `SLAVE_OUT(49) | `SLAVE_OUT(50) | `SLAVE_OUT(51) |
        `SLAVE_OUT(52) | `SLAVE_OUT(53) | `SLAVE_OUT(54) | `SLAVE_OUT(55) |
        `SLAVE_OUT(56) | `SLAVE_OUT(57) | `SLAVE_OUT(58) | `SLAVE_OUT(59) |
        `SLAVE_OUT(60) | `SLAVE_OUT(61) | `SLAVE_OUT(62) | `SLAVE_OUT(63);

    generate
        for (genvar i = 0; i < 16; i++) begin
            assign `MASTER_IN(i) = {
                d_opcode, d_param, d_size, d_source, d_sink,
                d_denied, d_data, d_corrupt, d_valid, a_ready
            } & {86{owner_valid & owner_bitmap[i]}};
        end
    endgenerate

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            owner_bitmap <= 16'b0;
            owner_valid <= `FALSE;
        end else begin
            if (set_owner) begin
                owner_bitmap <= abt_grant;
                owner_valid <= `TRUE;
            end

            if (clr_owner) begin
                owner_bitmap <= 16'b0;
                owner_valid <= `FALSE;
            end
        end
    end

    dbg_crossbar_dp u_dbg_crossbar_dp (
    	.clk       (clk       ),
        .rst_n     (rst_n     ),
        .a_opcode  (a_opcode  ),
        .a_param   (a_param   ),
        .a_size    (a_size    ),
        .a_source  (a_source  ),
        .a_address (a_address ),
        .a_mask    (a_mask    ),
        .a_data    (a_data    ),
        .a_corrupt (a_corrupt ),
        .a_valid   (a_valid   ),
        .a_ready   (a_ready   ),
        .chip_sel  (chip_sel  ),
        .chip_addr (chip_addr )
    );

endmodule
