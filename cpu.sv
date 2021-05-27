`timescale 1ns / 1ps

`include "isa.vh"
`include "csr.vh"

module cpu (
    input wire      clk,
    input wire      rst_n,

    input wire      clear,
    output wire     if_request,
    tilelink.master if_phy_bus,
    output wire     ma_request,
    tilelink.master ma_phy_bus
);

    wire stall;

    wire trap_en;
    wire [63:0] trap_pc;

    wire bj_en;
    wire [63:0] bj_pc;

    wire [31:0] inst;

    wire [63:0] id_pc;
    wire [4:0]  id_rs1;
    wire [4:0]  id_rs2;
    wire [63:0] id_data1;
    wire [63:0] id_data2;

    wire [63:0] ex_pc;
    wire [4:0]  ex_rd;
    wire [4:0]  ex_rs1;
    wire [4:0]  ex_rs2;
    wire [63:0] ex_data1;
    wire [63:0] ex_data2;
    wire [63:0] ex_imm;
    wire ex_with_imm;
    wire ex_comp;

    wire [63:0] ma_pc;
    wire [4:0]  ma_rd;
    wire [63:0] ma_ret;
    wire [63:0] ma_data1;
    wire [63:0] ma_data2;

    wire [63:0] ma_out;

    wire [63:0] wb_pc;
    wire [4:0]  wb_rd;
    wire [63:0] wb_out;

    wire [63:0] fwd1;
    wire [63:0] fwd2;

    wire [4:0]  ex_cause;
    wire [63:0] ex_tval;
    wire        ma_page_fault;
    wire [63:0] ma_pf_tval;

    wire [4:0]  cause = ma_page_fault ? `MCAUSE_LOAD_PAGE_FAULT : ex_cause;
    wire [63:0] tval = ma_page_fault ? ma_pf_tval : ex_tval;

    wire [63:0] csr_data;
    wire        op_csr;
    wire [63:0] satp;

    alu_ops ex_alu_ops();
    io_ops  ex_io_ops();
    bj_ops  ex_bj_ops();
    sys_ops ex_sys_ops();

    io_ops  ma_io_ops();

    tilelink ma_virt_bus();

    fetch u_fetch (
    	.clk     (clk       ),
        .rst_n   (rst_n     ),
        .stall   (stall     ),
        .clear   (clear     ),
        .trap_en (trap_en   ),
        .trap_pc (trap_pc   ),
        .bj_en   (bj_en     ),
        .bj_pc   (bj_pc     ),
        .inst    (inst      ),
        .pc      (id_pc     ),

        .request (if_request),
        .bus     (if_phy_bus)
    );

    decode u_decode (
    	.clk            (clk            ),
        .rst_n          (rst_n          ),
        .stall          (stall          ),
        .clear          (clear          ),
        .trap_en        (trap_en        ),
        .bj_en          (bj_en          ),
        .pc_in          (id_pc          ),
        .inst_in        (inst           ),
        .rs1            (id_rs1         ),
        .rs2            (id_rs2         ),
        .data1          (id_data1       ),
        .data2          (id_data2       ),
        .pc_out         (ex_pc          ),
        .rd_out         (ex_rd          ),
        .rs1_out        (ex_rs1         ),
        .rs2_out        (ex_rs2         ),
        .data1_out      (ex_data1       ),
        .data2_out      (ex_data2       ),
        .imm_out        (ex_imm         ),
        .with_imm_out   (ex_with_imm    ),
        .compressed_out (ex_comp        ),
        .alu_ops_out    (ex_alu_ops     ),
        .io_ops_out     (ex_io_ops      ),
        .bj_ops_out     (ex_bj_ops      ),
        .sys_ops_out    (ex_sys_ops     )
    );

    execute u_execute (
    	.clk        (clk        ),
        .rst_n      (rst_n      ),
        .clear      (clear      ),
        .stall      (stall      ),
        .trap_en    (trap_en    ),
        .alu_ops    (ex_alu_ops ),
        .io_ops     (ex_io_ops  ),
        .bj_ops     (ex_bj_ops  ),
        .sys_ops    (ex_sys_ops ),
        .compressed (ex_comp    ),
        .pc         (ex_pc      ),
        .rd         (ex_rd      ),
        .imm        (ex_imm     ),
        .with_imm   (ex_with_imm),
        .fwd1       (fwd1       ),
        .fwd2       (fwd2       ),
        .bj_pc      (bj_pc      ),
        .bj_en      (bj_en      ),
        .io_ops_out (ma_io_ops  ),
        .pc_out     (ma_pc      ),
        .rd_out     (ma_rd      ),
        .result_out (ma_ret     ),
        .data1_out  (ma_data1   ),
        .data2_out  (ma_data2   ),
        .cause_out  (ex_cause   ),
        .tval_out   (ex_tval    )
    );

    access u_access (
    	.clk      (clk          ),
        .rst_n    (rst_n        ),
        .clear    (clear        ),
        .trap_en  (trap_en      ),
        .io_ops   (ma_io_ops    ),
        .pc       (ma_pc        ),
        .rd       (ma_rd        ),
        .result   (ma_ret       ),
        .data2    (ma_data2     ),
        .csr_data (csr_data     ),
        .op_csr   (op_csr       ),
        .ma_out   (ma_out       ),
        .pc_out   (wb_pc        ),
        .rd_out   (wb_rd        ),
        .data_out (wb_out       ),
        .stall    (stall        ),
        .request  (ma_request   ),
        .bus      (ma_virt_bus  )
    );

    mmu u_ma_mmu (
        .clk        (clk            ),
        .rst_n      (rst_n          ),
        .satp       (satp           ),
        .page_fault (ma_page_fault  ),
        .tval       (ma_pf_tval     ),
        .virt_bus   (ma_virt_bus    ),
        .phy_bus    (ma_phy_bus     )
    );

    forward u_forward (
    	.rs1      (ex_rs1       ),
        .data1    (ex_data1     ),
        .rs2      (ex_rs2       ),
        .data2    (ex_data2     ),
        .ma_rd    (ma_rd        ),
        .ma_out   (ma_out       ),
        .wb_rd    (wb_rd        ),
        .wb_out   (wb_out       ),
        .out1     (fwd1         ),
        .out2     (fwd2         )
    );

    regfile u_regfile (
        .clk     (clk     ),
        .rst_n   (rst_n   ),
        .rs1     (id_rs1  ),
        .data1   (id_data1),
        .rs2     (id_rs2  ),
        .data2   (id_data2),
        .wb_rd   (wb_rd   ),
        .wb_out  (wb_out  )
    );

    csr u_csr (
        .clk      (clk      ),
        .rst_n    (rst_n    ),
        .pc       (ma_pc    ),
        .cause    (cause    ),
        .tval     (tval     ),
        .wdata    (ma_data1 ),
        .rdata    (csr_data ),
        .r_valid  (op_csr   ),
        .satp     (satp     ),
        .trap_en  (trap_en  ),
        .trap_pc  (trap_pc  )
    );

    dbg_regfile u_dbg_regfile (
    	.clk   (clk   ),
        .rst_n (rst_n ),
        .pc    (wb_pc ),
        .rd    (wb_rd ),
        .data  (wb_out)
    );

endmodule