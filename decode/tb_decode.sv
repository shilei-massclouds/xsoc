/*
 * [decode]
 * if-id -- decode -- regfile
 *            |          |
 *          id-ex -------
 */

`timescale 1ns / 1ps

`include "isa.vh"

module tb_decode;

    wire clk;
    wire rst_n;

    reg  [31:0] inst_in;

    wire [63:0] pc_in   = 64'h100;
    wire [4:0]  wb_rd   = 5'h3;
    wire [63:0] wb_data = 64'h800;
    wire stall      = `DISABLE;
    wire clear      = `DISABLE;
    wire trap_en    = `DISABLE;
    wire bj_en      = `DISABLE;

    wire [63:0] pc;
    wire [63:0] data1, data2;
    wire [63:0] data1_from, data2_from;
    wire [4:0]  rd, rs1, rs2;
    wire [4:0]  rs1_to, rs2_to;
    wire [63:0] imm;
    wire with_imm;
    wire compressed;

    alu_ops alu_ops();
    io_ops  io_ops();
    bj_ops  bj_ops();
    sys_ops sys_ops();

    clk_rst u_clk_rst (
        .clk   (clk   ),
        .rst_n (rst_n )
    );

    decode u_decode (
        .clk            (clk       ),
        .rst_n          (rst_n     ),
        .stall          (stall     ),
        .clear          (clear     ),
        .trap_en        (trap_en   ),
        .bj_en          (bj_en     ),
        .pc_in          (pc_in     ),
        .inst_in        (inst_in   ),
        .rs1            (rs1_to    ),
        .rs2            (rs2_to    ),
        .data1          (data1_from),
        .data2          (data2_from),
        .pc_out         (pc        ),
        .rd_out         (rd        ),
        .rs1_out        (rs1       ),
        .rs2_out        (rs2       ),
        .data1_out      (data1     ),
        .data2_out      (data2     ),
        .imm_out        (imm       ),
        .with_imm_out   (with_imm  ),
        .compressed_out (compressed),
        .alu_ops_out    (alu_ops   ),
        .io_ops_out     (io_ops    ),
        .bj_ops_out     (bj_ops    ),
        .sys_ops_out    (sys_ops   )
    );

    regfile u_regfile (
        .clk     (clk       ),
        .rst_n   (rst_n     ),
        .rs1     (rs1_to    ),
        .data1   (data1_from),
        .rs2     (rs2_to    ),
        .data2   (data2_from),
        .wb_rd   (wb_rd     ),
        .wb_data (wb_data   )
    );

    initial begin
        #40 inst_in <= 32'h0041a283;
        #30 inst_in <= 32'h0081a303;
        #30 inst_in <= 32'h006283b3;
        #30 inst_in <= 32'h0071a623;
    end

    initial begin
        $monitor($time,,
                 "rd(%x) rs(%x,%x) data(%x,%x,%x,%x) alu(%x) mem(%x,%x) bj(%x,%x)",
                 rd, rs1, rs2, data1, data2, imm, with_imm,
                 alu_ops.add_op, io_ops.load_op, io_ops.store_op,
                 bj_ops.beq_op, bj_ops.jal_op);

        #1024 $finish();
    end

endmodule
