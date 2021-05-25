`timescale 1ns / 1ps

`include "isa.vh"

module execute (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         clear,
    input  wire         stall,

    alu_ops.dst         alu_ops,
    io_ops.dst          io_ops,
    bj_ops.dst          bj_ops,
    sys_ops.dst         sys_ops,

    input  wire         compressed,

    input  wire [63:0]  pc,
    input  wire [4:0]   rd,
    input  wire [63:0]  imm,
    input  wire         with_imm,

    input  wire [63:0]  fwd1,
    input  wire [63:0]  fwd2,

    output wire [63:0]  trap_pc,
    output wire         trap_en,
    output wire [63:0]  bj_pc,
    output wire         bj_en,

    io_ops.src          io_ops_out,

    output wire [63:0]  pc_out,
    output wire [4:0]   rd_out,
    output wire [63:0]  result_out,
    output wire [63:0]  data2_out
);

    wire [63:0] result;
    wire [63:0] csr_data;

    system_ctl u_system_ctl (
    	.clk      (clk      ),
        .rst_n    (rst_n    ),
        .sys_ops  (sys_ops  ),
        .pc       (pc       ),
        .data1    (fwd1     ),
        .imm      (imm      ),
        .with_imm (with_imm ),
        .csr_data (csr_data ),
        .trap_en  (trap_en  ),
        .trap_pc  (trap_pc  )
    );

    alu u_alu (
        .alu_ops    (alu_ops    ),
        .io_ops     (io_ops     ),
        .bj_ops     (bj_ops     ),
    	.compressed (compressed ),
        .pc         (pc         ),
        .fwd1       (fwd1       ),
        .fwd2       (fwd2       ),
        .imm        (imm        ),
        .with_imm   (with_imm   ),
        .result     (result     )
    );

    jmp_br u_jmp_br (
        .bj_ops  (bj_ops  ),
        .stall   (stall   ),
        .pc      (pc      ),
        .data1   (fwd1    ),
        .imm     (imm     ),
        .result  (result  ),
        .bj_en   (bj_en   ),
        .bj_pc   (bj_pc   )
    );

    wire op_csr = sys_ops.csrrw_op | sys_ops.csrrs_op | sys_ops.csrrc_op;
    wire [63:0] result_in = op_csr ? csr_data : result;

    stage_ex_ma u_stage_ex_ma (
    	.clk         (clk         ),
        .rst_n       (rst_n       ),
        .clear       (clear       ),
        .stall       (stall       ),
        .trap_en     (trap_en     ),
        .pc_in       (pc          ),
        .rd_in       (rd          ),
        .result_in   (result_in   ),
        .data2_in    (fwd2        ),
        .io_ops_in   (io_ops      ),
        .pc_out      (pc_out      ),
        .rd_out      (rd_out      ),
        .result_out  (result_out  ),
        .data2_out   (data2_out   ),
        .io_ops_out  (io_ops_out  )
    );

    dbg_execute u_dbg_execute (
    	.clk     (clk       ),
        .rst_n   (rst_n     ),
        .stall   (stall     ),
        .pc      (pc        ),
        .rd      (rd        ),
        .result  (result_in ),
        .data2   (fwd2      ),
        .bj_en   (bj_en     ),
        .bj_pc   (bj_pc     ),
        .trap_en (trap_en   ),
        .trap_pc (trap_pc   ),
        .io_ops  (io_ops    ),
        .bj_ops  (bj_ops    ),
        .sys_ops (sys_ops   )
    );

endmodule
