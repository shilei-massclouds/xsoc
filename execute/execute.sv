`timescale 1ns / 1ps

`include "isa.vh"

module execute (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         clear,
    input  wire         stall,
    input  wire         trap_en,

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
    input  wire [4:0]   cause_in,
    input  wire [63:0]  tval_in,

    output wire [63:0]  bj_pc,
    output wire         bj_en,

    io_ops.src          io_ops_out,

    output wire [63:0]  pc_out,
    output wire [4:0]   rd_out,
    output wire [63:0]  result_out,
    output wire [63:0]  data1_out,
    output wire [63:0]  data2_out,
    output wire [4:0]   cause_out,
    output wire [63:0]  tval_out
);

    wire [63:0] result;
    wire [4:0]  _cause;
    wire [63:0] _tval;

    wire [63:0] data1 = with_imm ? imm : fwd1;

    csr_ecall u_csr_ecall (
        .sys_ops  (sys_ops  ),
        .cause_in (cause_in ),
        .tval_in  (tval_in  ),
        .cause_out(_cause   ),
        .tval_out (_tval    )
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

    stage_ex_ma u_stage_ex_ma (
        .clk         (clk         ),
        .rst_n       (rst_n       ),
        .clear       (clear       ),
        .stall       (stall       ),
        .trap_en     (trap_en     ),
        .pc_in       (pc          ),
        .rd_in       (rd          ),
        .result_in   (result      ),
        .data1_in    (data1       ),
        .data2_in    (fwd2        ),
        .cause_in    (_cause      ),
        .tval_in     (_tval       ),
        .io_ops_in   (io_ops      ),
        .pc_out      (pc_out      ),
        .rd_out      (rd_out      ),
        .result_out  (result_out  ),
        .data1_out   (data1_out   ),
        .data2_out   (data2_out   ),
        .cause_out   (cause_out   ),
        .tval_out    (tval_out    ),
        .io_ops_out  (io_ops_out  )
    );

    dbg_execute u_dbg_execute (
        .clk     (clk       ),
        .rst_n   (rst_n     ),
        .stall   (stall     ),
        .pc      (pc        ),
        .rd      (rd        ),
        .result  (result    ),
        .data2   (fwd2      ),
        .cause   (cause_in  ),
        .tval    (tval_in   ),
        .bj_en   (bj_en     ),
        .bj_pc   (bj_pc     ),
        .io_ops  (io_ops    ),
        .bj_ops  (bj_ops    ),
        .sys_ops (sys_ops   )
    );

endmodule
