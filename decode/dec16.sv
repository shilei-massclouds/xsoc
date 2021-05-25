module dec16 (
    input wire [15:0]   inst,
    output wire [4:0]   rd,
    output wire [4:0]   rs1,
    output wire [4:0]   rs2,
    output wire [63:0]  imm,
    output wire         with_imm,
    alu_ops.src         alu_ops,
    io_ops.src          io_ops,
    bj_ops.src          bj_ops,
    sys_ops.src         sys_ops
);
 
    wire [1:0] op = inst[1:0];
    wire [2:0] funct3 = inst[15:13];
    wire bit12 = inst[12];

    wire c_00_000 = (op == 2'b00) & (funct3 == 3'b000);
    wire c_00_010 = (op == 2'b00) & (funct3 == 3'b010);
    wire c_00_011 = (op == 2'b00) & (funct3 == 3'b011);
    wire c_00_110 = (op == 2'b00) & (funct3 == 3'b110);
    wire c_00_111 = (op == 2'b00) & (funct3 == 3'b111);
    wire c_01_000 = (op == 2'b01) & (funct3 == 3'b000);
    wire c_01_001 = (op == 2'b01) & (funct3 == 3'b001);
    wire c_01_010 = (op == 2'b01) & (funct3 == 3'b010);
    wire c_01_011 = (op == 2'b01) & (funct3 == 3'b011);
    wire c_01_100 = (op == 2'b01) & (funct3 == 3'b100);
    wire c_01_101 = (op == 2'b01) & (funct3 == 3'b101);
    wire c_01_110 = (op == 2'b01) & (funct3 == 3'b110);
    wire c_01_111 = (op == 2'b01) & (funct3 == 3'b111);
    wire c_10_000 = (op == 2'b10) & (funct3 == 3'b000);
    wire c_10_010 = (op == 2'b10) & (funct3 == 3'b010);
    wire c_10_011 = (op == 2'b10) & (funct3 == 3'b011);
    wire c_10_100 = (op == 2'b10) & (funct3 == 3'b100);
    wire c_10_110 = (op == 2'b10) & (funct3 == 3'b110);
    wire c_10_111 = (op == 2'b10) & (funct3 == 3'b111);

    wire [4:0] rd_rs1 = inst[11:7];
    wire rd_rs1_zero = ~(|rd_rs1);

    wire [4:0] rs2_bits = inst[6:2];
    wire rs2_zero = ~(|rs2_bits);

    wire rc_addi4spn = c_00_000;
    wire rc_lw       = c_00_010;
    wire rc_ld       = c_00_011;
    wire rc_sw       = c_00_110;
    wire rc_sd       = c_00_111;

    wire rc_lwsp = c_10_010;
    wire rc_ldsp = c_10_011;
    wire rc_swsp = c_10_110;
    wire rc_sdsp = c_10_111;

    wire rc_nop   = c_01_000 & rd_rs1_zero;
    wire rc_addi  = c_01_000 & ~rd_rs1_zero;
    wire rc_addiw = c_01_001 & ~rd_rs1_zero;

    wire rc_li   = c_01_010;
    wire rc_j    = c_01_101;
    wire rc_jr   = c_10_100 & ~bit12 & rs2_zero;
    wire rc_mv   = c_10_100 & ~bit12 & ~rs2_zero;
    wire rc_jalr = c_10_100 & bit12 & rs2_zero;
    wire rc_add  = c_10_100 & bit12 & ~rs2_zero;

    wire rc_addi16sp = c_01_011 & (rd_rs1 == 5'b00010);
    wire rc_lui      = c_01_011 & (rd_rs1 != 5'b00010);

    wire rc_srli = c_01_100 & (inst[11:10] == 2'b00);
    wire rc_srai = c_01_100 & (inst[11:10] == 2'b01);
    wire rc_andi = c_01_100 & (inst[11:10] == 2'b10);
    wire rc_sub  = c_01_100 & (inst[12:10] == 3'b011) & (inst[6:5] == 2'b00);
    wire rc_xor  = c_01_100 & (inst[12:10] == 3'b011) & (inst[6:5] == 2'b01);
    wire rc_or   = c_01_100 & (inst[12:10] == 3'b011) & (inst[6:5] == 2'b10);
    wire rc_and  = c_01_100 & (inst[12:10] == 3'b011) & (inst[6:5] == 2'b11);

    wire rc_subw = c_01_100 & (inst[12:10] == 3'b111) & (inst[6:5] == 2'b00);
    wire rc_addw = c_01_100 & (inst[12:10] == 3'b111) & (inst[6:5] == 2'b01);

    wire rc_beqz = c_01_110;
    wire rc_bnez = c_01_111;

    wire rc_slli = c_10_000;
    wire rc_ebreak = c_10_100 & bit12 & rd_rs1_zero;

    wire [63:0] i_imm = {{58{inst[12]}}, inst[12], inst[6:2]};

    wire [63:0] ui_imm = {58'b0, inst[12], inst[6:2]};

    wire [63:0] j_imm = {{52{inst[12]}}, inst[12], inst[8], inst[10:9],
                         inst[6], inst[7], inst[2], inst[11], inst[5:3],
                         1'b0};

    wire [63:0] d_imm = {{54{inst[12]}}, inst[12], inst[4:3],
                         inst[5], inst[2], inst[6], 4'b0};

    wire [63:0] n_imm = {55'b0, inst[10:7], inst[12:11],
                         inst[5], inst[6], 2'b00};

    wire [63:0] u_imm = {57'b0, inst[5], inst[12:10], inst[6], 2'b00};

    wire [63:0] u_imm_d = {56'b0, inst[6:5], inst[12:10], 3'b000};

    wire [63:0] b_imm = {{55{inst[12]}}, inst[12], inst[6:5], inst[2],
                         inst[11:10], inst[4:3], 1'b0};

    wire [63:0] lwsp_imm = {56'b0, inst[3:2], inst[12], inst[6:4], 2'b00};
    wire [63:0] ldsp_imm = {55'b0, inst[4:2], inst[12], inst[6:5], 3'b000};
    wire [63:0] swsp_imm = {56'b0, inst[8:7], inst[12:9], 2'b00};
    wire [63:0] sdsp_imm = {55'b0, inst[9:7], inst[12:10], 3'b000};

    assign rd = ({5{rc_mv|rc_add|rc_li|
                    rc_addi|rc_addiw|rc_lui|rc_addi16sp|
                    rc_slli|
                    rc_lwsp|rc_ldsp}} & rd_rs1) |
                ({5{rc_addi4spn|rc_lw|rc_ld}} & {2'b01, inst[4:2]}) |
                ({5{rc_jalr}} & 5'b00001) |
                ({5{rc_andi|rc_sub|rc_xor|rc_or|rc_and|
                    rc_subw|rc_addw|rc_srli|rc_srai}} & {2'b01, inst[9:7]});

    assign rs1 = ({5{rc_jr|rc_jalr|rc_add|rc_addi|rc_addiw|
                     rc_slli|rc_addi16sp}} & rd_rs1) |
                 ({5{rc_lw|rc_ld|rc_sw|rc_sd|
                     rc_andi|rc_sub|rc_xor|rc_or|rc_and|rc_subw|rc_addw|
                     rc_beqz|rc_bnez|rc_srli|rc_srai}} & {2'b01, inst[9:7]}) |
                 ({5{rc_addi4spn|rc_lwsp|rc_ldsp|rc_swsp|rc_sdsp}} & 5'b00010);

    assign rs2 = ({5{rc_mv|rc_add|rc_swsp|rc_sdsp}} & rs2_bits) |
                 ({5{rc_sw|rc_sd|rc_sub|rc_xor|rc_or|rc_and|
                     rc_subw|rc_addw}} & {2'b01, inst[4:2]});

    /* IMM */
    assign imm = ({64{rc_j}} & j_imm) |
                 ({64{rc_li|rc_addi|rc_addiw|rc_andi}} & i_imm) |
                 ({64{rc_slli|rc_srli|rc_srai}} & ui_imm) |
                 ({64{rc_addi16sp}} & d_imm) |
                 ({64{rc_addi4spn}} & n_imm) |
                 ({64{rc_lw|rc_sw}} & u_imm) |
                 ({64{rc_ld|rc_sd}} & u_imm_d) |
                 ({64{rc_beqz|rc_bnez}} & b_imm) |
                 ({64{rc_lwsp}} & lwsp_imm) | ({64{rc_ldsp}} & ldsp_imm) |
                 ({64{rc_swsp}} & swsp_imm) | ({64{rc_sdsp}} & sdsp_imm) |
                 ({64{rc_lui}} & {i_imm[51:0], 12'b0});

    assign with_imm = rc_j | rc_li | rc_addi | rc_addiw | rc_lui |
                      rc_lw | rc_ld | rc_sw | rc_sd | rc_andi |
                      rc_lwsp | rc_ldsp | rc_swsp | rc_sdsp |
                      rc_slli | rc_srli | rc_srai |
                      rc_addi16sp | rc_addi4spn;

    wire add_op = rc_add | rc_addi | rc_addiw | rc_addw |
                  rc_mv | rc_li | rc_addi16sp | rc_addi4spn |
                  rc_lw | rc_ld | rc_sw | rc_sd |
                  rc_lwsp | rc_ldsp | rc_swsp | rc_sdsp;

    assign alu_ops.add_op    = add_op;
    assign alu_ops.sub_op    = rc_sub | rc_subw;
    assign alu_ops.and_op    = rc_and | rc_andi;
    assign alu_ops.or_op     = rc_or;
    assign alu_ops.xor_op    = rc_xor;
    assign alu_ops.sll_op    = rc_slli;
    assign alu_ops.srl_op    = rc_srli;
    assign alu_ops.sra_op    = rc_srai;
    assign alu_ops.slt_op    = 1'b0;
    assign alu_ops.lui_op    = rc_lui;
    assign alu_ops.auipc_op  = 1'b0;
    assign alu_ops.mul_op    = 1'b0;
    assign alu_ops.mulh_op   = 1'b0;
    assign alu_ops.mulhsu_op = 1'b0;
    assign alu_ops.div_op    = 1'b0;
    assign alu_ops.rem_op    = 1'b0;
    assign alu_ops.is_unsign = 1'b0;
    assign alu_ops.is_word   = rc_subw | rc_addw | rc_addiw;

    assign io_ops.load_op = rc_lw | rc_ld | rc_lwsp | rc_ldsp;
    assign io_ops.store_op = rc_sw | rc_sd | rc_swsp | rc_sdsp;
    assign io_ops.amo_add_op = 1'b0;
    assign io_ops.amo_swap_op = 1'b0;
    assign io_ops.lr_op = 1'b0;
    assign io_ops.sc_op = 1'b0;
    assign io_ops.amo_xor_op = 1'b0;
    assign io_ops.amo_or_op = 1'b0;
    assign io_ops.amo_and_op = 1'b0;
    assign io_ops.amo_min_op = 1'b0;
    assign io_ops.amo_max_op = 1'b0;
    assign io_ops.amo_minu_op = 1'b0;
    assign io_ops.amo_maxu_op = 1'b0;
    assign io_ops.size = {1'b0, funct3[1:0]};
    assign io_ops.mask = {{4{funct3[1]&funct3[0]}}, {2{funct3[1]}},
                          funct3[1]|funct3[0], 1'b1};

    assign bj_ops.beq_op = rc_beqz;
    assign bj_ops.bne_op = rc_bnez;
    assign bj_ops.blt_op = 1'b0;
    assign bj_ops.bge_op = 1'b0;
    assign bj_ops.bltu_op = 1'b0;
    assign bj_ops.bgeu_op = 1'b0;
    assign bj_ops.jal_op = rc_j;
    assign bj_ops.jalr_op = rc_jr | rc_jalr;

    assign sys_ops.ecall_op  = 1'b0;
    assign sys_ops.ebreak_op = rc_ebreak;
    assign sys_ops.mret_op   = 1'b0;
    assign sys_ops.wfi_op    = 1'b0;

    assign sys_ops.csrrw_op = 1'b0;
    assign sys_ops.csrrs_op = 1'b0;
    assign sys_ops.csrrc_op = 1'b0;

    assign sys_ops.csr_addr = 12'b0;
    
endmodule