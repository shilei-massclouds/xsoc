/*
 * [execute]
 * id_ex -- execute -- alu -- ex_ma
 *             |
 *          forwarding
 */

`timescale 1ns / 1ps

`include "isa.vh"

module tb_execute;

    wire clk;
    wire rst_n;

    alu_ops alu_ops();
    io_ops  io_ops();
    bj_ops  bj_ops();
    sys_ops sys_ops();

    wire [63:0] pc;
    wire [4:0]  rd;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [63:0] data1;
    wire [63:0] data2;
    wire [63:0] imm;
    wire        with_imm;

    wire [4:0]  ma_rd;
    wire [63:0] ma_out;
    wire [4:0]  wb_rd;
    wire [63:0] wb_out;

    io_ops  io_ops_out();

    wire [63:0] trap_pc;
    wire        trap_en;
    wire [63:0] bj_pc;
    wire        bj_en;

    wire [63:0] pc_out;
    wire [4:0]  rd_out;
    wire [63:0] result_out;
    wire [63:0] data2_out;

    wire [63:0] fwd1;
    wire [63:0] fwd2;

    clk_rst u_clk_rst (
        .clk   (clk   ),
        .rst_n (rst_n )
    );

    stimulator u_stimulator (
        .alu_ops    (alu_ops    ),
        .io_ops     (io_ops     ),
        .bj_ops     (bj_ops     ),
        .sys_ops    (sys_ops    ),
    	.clear      (clear      ),
        .stall      (stall      ),
        .compressed (compressed ),
        .pc         (pc         ),
        .rd         (rd         ),
        .rs1        (rs1        ),
        .rs2        (rs2        ),
        .data1      (data1      ),
        .data2      (data2      ),
        .imm        (imm        ),
        .with_imm   (with_imm   ),
        .ma_rd      (ma_rd      ),
        .ma_out     (ma_out     ),
        .wb_rd      (wb_rd      ),
        .wb_out     (wb_out     )
    );

    forward u_forward (
    	.rs1      (rs1      ),
        .data1    (data1    ),
        .rs2      (rs2      ),
        .data2    (data2    ),
        .ma_rd    (ma_rd    ),
        .ma_out   (ma_out   ),
        .wb_rd    (wb_rd    ),
        .wb_out   (wb_out   ),
        .out1     (fwd1     ),
        .out2     (fwd2     )
    );

    execute u_execute (
    	.clk        (clk        ),
        .rst_n      (rst_n      ),
        .clear      (clear      ),
        .stall      (stall      ),
        .alu_ops    (alu_ops    ),
        .io_ops     (io_ops     ),
        .bj_ops     (bj_ops     ),
        .sys_ops    (sys_ops    ),
        .compressed (compressed ),
        .pc         (pc         ),
        .rd         (rd         ),
        .imm        (imm        ),
        .with_imm   (with_imm   ),
        .fwd1       (fwd1       ),
        .fwd2       (fwd2       ),
        .trap_pc    (trap_pc    ),
        .trap_en    (trap_en    ),
        .bj_pc      (bj_pc      ),
        .bj_en      (bj_en      ),
        .io_ops_out (io_ops_out ),
        .pc_out     (pc_out     ),
        .rd_out     (rd_out     ),
        .result_out (result_out ),
        .data2_out  (data2_out  )
    );
    
    initial begin
        $monitor($time,, "rd(%x) result(%x) data2(%x) io(%x,%x)",
                 rd_out, result_out, data2_out,
                 io_ops_out.load_op, io_ops_out.store_op);

        #1024 $finish();
    end

endmodule
