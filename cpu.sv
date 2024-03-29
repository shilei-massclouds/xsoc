`timescale 1ns / 1ps

`include "isa.vh"
`include "csr.vh"

module cpu (
    input wire      clk,
    input wire      rst_n,

    input wire      clear,

    output wire [63:0] ma_pc,

    output wire     if_request,
    tilelink.master if_phy_bus,
    output wire     ma_request,
    tilelink.master ma_phy_bus
);

    bit  dump;
    bit  bubble;

    wire [1:0]  priv;
    wire stall;

    wire trap_en;
    wire [63:0] trap_pc;

    wire bj_en;
    wire [63:0] bj_pc;

    wire [31:0] inst;

    wire [63:0] if_pc;

    wire [31:0] id_inst = bubble ? {31'b0, 1'b1} : inst;

    wire [63:0] id_pc;
    wire [4:0]  id_rs1;
    wire [4:0]  id_rs2;
    wire [63:0] id_data1;
    wire [63:0] id_data2;
    wire [4:0]  id_cause;
    wire [63:0] id_tval;

    wire [63:0] ex_pc;
    wire [4:0]  ex_rd;
    wire [4:0]  ex_rs1;
    wire [4:0]  ex_rs2;
    wire [63:0] ex_data1;
    wire [63:0] ex_data2;
    wire [63:0] ex_imm;
    wire [4:0]  ex_cause;
    wire [63:0] ex_tval;
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

    wire [4:0]  ma_cause;
    wire [63:0] ma_tval;

    wire        if_page_fault;
    wire [63:0] if_pf_tval;

    wire        ma_page_fault;
    wire [63:0] ma_pf_tval;

    wire [4:0]  op = ma_page_fault ? `SYSOP_LOAD_PAGE_FAULT : ma_cause;
    wire [63:0] tval = ma_page_fault ? ma_pf_tval : ma_tval;

    wire [63:0] csr_data;
    wire        op_csr;
    wire [63:0] satp;

    wire [26:0]  if_tlb_addr;
    wire [43:0]  if_tlb_rdata;
    wire         if_tlb_hit;
    wire [43:0]  if_tlb_wdata;
    wire         if_tlb_update;

    wire [26:0]  ma_tlb_addr;
    wire [43:0]  ma_tlb_rdata;
    wire         ma_tlb_hit;
    wire [43:0]  ma_tlb_wdata;
    wire         ma_tlb_update;

    assign export_ma_pc = ma_pc;

    alu_ops ex_alu_ops();
    io_ops  ex_io_ops();
    bj_ops  ex_bj_ops();
    sys_ops ex_sys_ops();

    io_ops  ma_io_ops();

    tilelink if_virt_bus();
    tilelink ma_virt_bus();

    wire invalid;

    fetch u_fetch (
        .clk        (clk       ),
        .rst_n      (rst_n     ),
        .stall      (stall     ),
        .clear      (clear     ),
        .trap_en    (trap_en   ),
        .trap_pc    (trap_pc   ),
        .bj_en      (bj_en     ),
        .bj_pc      (bj_pc     ),
        .invalid    (invalid   ),
        .page_fault (if_page_fault),
        .tval       (if_pf_tval),
        .if_pc      (if_pc     ),
        .inst_out   (inst      ),
        .pc_out     (id_pc     ),
        .cause_out  (id_cause  ),
        .tval_out   (id_tval   ),
        .request    (if_request),
        .bus        (if_virt_bus)
    );

    mmu u_if_mmu (
        .clk        (clk            ),
        .rst_n      (rst_n          ),
        .pc         (if_pc          ),
        .priv       (priv           ),
        .satp       (satp           ),
        .invalid    (invalid        ),
        .tlb_addr   (if_tlb_addr    ),
        .tlb_rdata  (if_tlb_rdata   ),
        .tlb_hit    (if_tlb_hit     ),
        .tlb_wdata  (if_tlb_wdata   ),
        .tlb_update (if_tlb_update  ),
        .page_fault (if_page_fault  ),
        .tval       (if_pf_tval     ),
        .virt_bus   (if_virt_bus    ),
        .phy_bus    (if_phy_bus     )
    );

    decode u_decode (
    	.clk            (clk            ),
        .rst_n          (rst_n          ),
        .stall          (stall          ),
        .clear          (clear          ),
        .trap_en        (trap_en        ),
        .bj_en          (bj_en          ),
        .pc_in          (id_pc          ),
        .inst_in        (id_inst        ),
        .rs1            (id_rs1         ),
        .rs2            (id_rs2         ),
        .data1          (id_data1       ),
        .data2          (id_data2       ),
        .cause_in       (id_cause       ),
        .tval_in        (id_tval        ),
        .pc_out         (ex_pc          ),
        .rd_out         (ex_rd          ),
        .rs1_out        (ex_rs1         ),
        .rs2_out        (ex_rs2         ),
        .data1_out      (ex_data1       ),
        .data2_out      (ex_data2       ),
        .imm_out        (ex_imm         ),
        .with_imm_out   (ex_with_imm    ),
        .compressed_out (ex_comp        ),
        .cause_out      (ex_cause       ),
        .tval_out       (ex_tval        ),
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
        .priv       (priv       ),
        .pc         (ex_pc      ),
        .rd         (ex_rd      ),
        .imm        (ex_imm     ),
        .with_imm   (ex_with_imm),
        .fwd1       (fwd1       ),
        .fwd2       (fwd2       ),
        .cause_in   (ex_cause   ),
        .tval_in    (ex_tval    ),
        .bj_pc      (bj_pc      ),
        .bj_en      (bj_en      ),
        .io_ops_out (ma_io_ops  ),
        .pc_out     (ma_pc      ),
        .rd_out     (ma_rd      ),
        .result_out (ma_ret     ),
        .data1_out  (ma_data1   ),
        .data2_out  (ma_data2   ),
        .cause_out  (ma_cause   ),
        .tval_out   (ma_tval    )
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
        .invalid  (invalid      ),
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
        .pc         (ma_pc          ),
        .priv       (priv           ),
        .satp       (satp           ),
        .invalid    (invalid        ),
        .tlb_addr   (ma_tlb_addr    ),
        .tlb_rdata  (ma_tlb_rdata   ),
        .tlb_hit    (ma_tlb_hit     ),
        .tlb_wdata  (ma_tlb_wdata   ),
        .tlb_update (ma_tlb_update  ),
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
        .op       (op       ),
        .tval     (tval     ),
        .wdata    (ma_data1 ),
        .rdata    (csr_data ),
        .r_valid  (op_csr   ),
        .priv     (priv     ),
        .satp     (satp     ),
        .invalid  (invalid  ),
        .trap_en  (trap_en  ),
        .trap_pc  (trap_pc  )
    );

    tlb u_tlb (
        .clk       (clk           ),
        .rst_n     (rst_n         ),
        .invalid   (invalid       ),
        .if_addr   (if_tlb_addr   ),
        .if_rdata  (if_tlb_rdata  ),
        .if_hit    (if_tlb_hit    ),
        .if_wdata  (if_tlb_wdata  ),
        .if_update (if_tlb_update ),
        .ma_addr   (ma_tlb_addr   ),
        .ma_rdata  (ma_tlb_rdata  ),
        .ma_hit    (ma_tlb_hit    ),
        .ma_wdata  (ma_tlb_wdata  ),
        .ma_update (ma_tlb_update )
    );

    dbg_regfile u_dbg_regfile (
    	.clk   (clk   ),
        .rst_n (rst_n ),
        .pc    (wb_pc ),
        .rd    (wb_rd ),
        .data  (wb_out)
    );

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            dump <= 1'b0;
        end else begin
            if (dump) begin
                dump_mem();
                dump_reg(u_regfile.data);
                dump_csr(u_csr.csr);
                dump_priv(u_csr._priv);
                $finish();
            end else if (wait_breakpoint(wb_pc)) begin
                dump <= 1'b1;
            end
        end
    end

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            bubble <= 1'b0;
        end else begin
            if (bubble) begin
            end else if (wait_breakpoint(id_pc)) begin
                bubble <= 1'b1;
                dump_pc(id_pc, &(inst[1:0]));
                $display($time,, "inst: [%x] %x\n", id_pc, inst);
            end
        end
    end

endmodule
