`timescale 1ns / 1ps

`include "isa.vh"

module decode (
    input wire  clk,
    input wire  rst_n,

    input wire  stall,
    input wire  clear,
    input wire  trap_en,
    input wire  bj_en,

    input wire  [63:0]  pc_in,
    input wire  [31:0]  inst_in,
    output wire [4:0]   rs1,
    output wire [4:0]   rs2,
    input wire  [63:0]  data1,
    input wire  [63:0]  data2,
    input wire  [4:0]   cause_in,
    input wire  [63:0]  tval_in,

    output wire [63:0]  pc_out,
    output wire [4:0]   rd_out,
    output wire [4:0]   rs1_out,
    output wire [4:0]   rs2_out,
    output wire [63:0]  data1_out,
    output wire [63:0]  data2_out,
    output wire [63:0]  imm_out,
    output wire         with_imm_out,
    output wire         compressed_out,
    output wire [4:0]   cause_out,
    output wire [63:0]  tval_out,
    alu_ops.src         alu_ops_out,
    io_ops.src          io_ops_out,
    bj_ops.src          bj_ops_out,
    sys_ops.src         sys_ops_out
);

    wire [4:0]   rd_32, rd_16, rd;
    wire [4:0]   rs1_32, rs1_16;
    wire [4:0]   rs2_32, rs2_16;
    wire [63:0]  imm_32, imm_16, imm;
    wire         with_imm_32, with_imm_16, with_imm;

    alu_ops alu_ops();
    alu_ops alu_ops_32();
    alu_ops alu_ops_16();
    io_ops  io_ops();
    io_ops  io_ops_32();
    io_ops  io_ops_16();
    bj_ops  bj_ops();
    bj_ops  bj_ops_32();
    bj_ops  bj_ops_16();
    sys_ops sys_ops();
    sys_ops sys_ops_32();
    sys_ops sys_ops_16();

    dec32 dec32(inst_in, rd_32, rs1_32, rs2_32, imm_32, with_imm_32,
                alu_ops_32, io_ops_32, bj_ops_32, sys_ops_32);

    dec16 dec16(inst_in[15:0], rd_16, rs1_16, rs2_16, imm_16, with_imm_16,
                alu_ops_16, io_ops_16, bj_ops_16, sys_ops_16);

    wire compressed = (inst_in[1:0] != 2'b11);

    assign rd = compressed ? rd_16 : rd_32;
    assign rs1 = compressed ? rs1_16 : rs1_32;
    assign rs2 = compressed ? rs2_16 : rs2_32;
    assign imm = compressed ? imm_16 : imm_32;
    assign with_imm = compressed ? with_imm_16 : with_imm_32;

    dec_sel dec_sel (
        compressed,
        alu_ops, alu_ops_16, alu_ops_32, io_ops, io_ops_16, io_ops_32,
        bj_ops, bj_ops_16, bj_ops_32, sys_ops, sys_ops_16, sys_ops_32
    );

    stage_id_ex u_stage_id_ex (
        .clk            (clk            ),
        .rst_n          (rst_n          ),
        .clear          (clear          ),
        .stall          (stall          ),
        .bj_en          (bj_en          ),
        .trap_en        (trap_en        ),
        .pc_in          (pc_in          ),
        .rd_in          (rd             ),
        .rs1_in         (rs1            ),
        .rs2_in         (rs2            ),
        .data1_in       (data1          ),
        .data2_in       (data2          ),
        .imm_in         (imm            ),
        .with_imm_in    (with_imm       ),
        .compressed_in  (compressed     ),
        .cause_in       (cause_in       ),
        .tval_in        (tval_in        ),
        .alu_ops_in     (alu_ops        ),
        .io_ops_in      (io_ops         ),
        .bj_ops_in      (bj_ops         ),
        .sys_ops_in     (sys_ops        ),
        .pc_out         (pc_out         ),
        .rd_out         (rd_out         ),
        .rs1_out        (rs1_out        ),
        .rs2_out        (rs2_out        ),
        .data1_out      (data1_out      ),
        .data2_out      (data2_out      ),
        .imm_out        (imm_out        ),
        .with_imm_out   (with_imm_out   ),
        .compressed_out (compressed_out ),
        .cause_out      (cause_out      ),
        .tval_out       (tval_out       ),
        .alu_ops_out    (alu_ops_out    ),
        .io_ops_out     (io_ops_out     ),
        .bj_ops_out     (bj_ops_out     ),
        .sys_ops_out    (sys_ops_out    )
    );

    dbg_decode u_dbg_decode (
    	.clk      (clk      ),
        .rst_n    (rst_n    ),
        .pc       (pc_in    ),
        .inst     (inst_in  ),
        .rd       (rd       ),
        .data1    (data1    ),
        .data2    (data2    ),
        .imm      (imm      ),
        .with_imm (with_imm ),
        .cause    (cause_in ),
        .tval     (tval_in  )
    );

endmodule
