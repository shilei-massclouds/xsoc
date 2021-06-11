`timescale 1ns / 1ps

`include "csr.vh"

`define ASSIGN_BUS(to, from, prop) \
    assign to.prop = paging ? prop : from.prop

module mmu (
    input  wire         clk,
    input  wire         rst_n,

    input  wire [63:0]  pc,

    input  wire [1:0]   priv,
    input  wire [63:0]  satp,
    input  wire         invalid,

    output wire [26:0]  tlb_addr,

    input  wire [43:0]  tlb_rdata,
    input  wire         tlb_hit,

    output reg  [43:0]  tlb_wdata,
    output reg          tlb_update,

    output reg          page_fault,
    output reg  [63:0]  tval,

    tilelink.slave      virt_bus,
    tilelink.master     phy_bus
);

    bit [2:0]     a_opcode;
    bit [2:0]     a_param;
    bit [2:0]     a_size;
    bit [3:0]     a_source;
    bit [63:0]    a_address;
    bit [7:0]     a_mask;
    bit [63:0]    a_data;
    bit           a_corrupt;
    bit           a_valid;
    bit           a_ready;

    bit [2:0]     d_opcode;
    bit [1:0]     d_param;
    bit [2:0]     d_size;
    bit [3:0]     d_source;
    bit [5:0]     d_sink;
    bit           d_denied;
    bit [63:0]    d_data;
    bit           d_corrupt;
    bit           d_valid;

    wire          d_ready = `TRUE;

    bit [2:0]     ori_a_opcode;
    bit [2:0]     ori_a_param;
    bit [2:0]     ori_a_size;
    bit [3:0]     ori_a_source;
    bit [63:0]    ori_a_address;
    bit [7:0]     ori_a_mask;
    bit [63:0]    ori_a_data;
    bit           ori_a_corrupt;
    bit           ori_a_valid;

    wire paging = (priv == `S_MODE) & ~(satp[63:60] == 4'h0);
    wire [43:0] root_ppn = satp[43:0];

    logic [3:0] state, next_state;
    dff #(4, 4'b0) dff_state(clk, rst_n, `DISABLE, `DISABLE, next_state, state);

    `ASSIGN_BUS(phy_bus, virt_bus, a_opcode);
    `ASSIGN_BUS(phy_bus, virt_bus, a_param);
    `ASSIGN_BUS(phy_bus, virt_bus, a_size);
    `ASSIGN_BUS(phy_bus, virt_bus, a_source);
    `ASSIGN_BUS(phy_bus, virt_bus, a_address);
    `ASSIGN_BUS(phy_bus, virt_bus, a_mask);
    `ASSIGN_BUS(phy_bus, virt_bus, a_data);
    `ASSIGN_BUS(phy_bus, virt_bus, a_corrupt);
    `ASSIGN_BUS(phy_bus, virt_bus, a_valid);
    `ASSIGN_BUS(phy_bus, virt_bus, d_ready);

    `ASSIGN_BUS(virt_bus, phy_bus, d_opcode);
    `ASSIGN_BUS(virt_bus, phy_bus, d_param);
    `ASSIGN_BUS(virt_bus, phy_bus, d_size);
    `ASSIGN_BUS(virt_bus, phy_bus, d_source);
    `ASSIGN_BUS(virt_bus, phy_bus, d_sink);
    `ASSIGN_BUS(virt_bus, phy_bus, d_denied);
    `ASSIGN_BUS(virt_bus, phy_bus, d_data);
    `ASSIGN_BUS(virt_bus, phy_bus, d_corrupt);
    `ASSIGN_BUS(virt_bus, phy_bus, d_valid);
    `ASSIGN_BUS(virt_bus, phy_bus, a_ready);

    localparam PTE_BIT_V = 0;
    localparam PTE_BIT_R = 1;
    localparam PTE_BIT_W = 2;
    localparam PTE_BIT_X = 3;

    reg [63:0] pte;

    wire branch = (~(pte[PTE_BIT_R] | pte[PTE_BIT_W] | pte[PTE_BIT_X])) &
                  pte[PTE_BIT_V];

    wire leaf = (pte[PTE_BIT_R] | (~pte[PTE_BIT_W] & pte[PTE_BIT_X])) &
                pte[PTE_BIT_V];

    wire except = ~branch & ~leaf;

    /* State transition */
    localparam S_IDLE = 4'h0;
    localparam S_PGD  = 4'h1;
    localparam S_PMD  = 4'h2;
    localparam S_PT   = 4'h3;
    localparam S_ADDR = 4'h4;
    localparam S_DATA = 4'h5;
    localparam S_TRAP = 4'h6;
    localparam S_PGD_DATA = 4'h8;
    localparam S_PMD_DATA = 4'h9;
    localparam S_PT_DATA  = 4'ha;

    assign tlb_addr = (state == S_IDLE) ? virt_bus.a_address[38:12] :
                                          ori_a_address[38:12];

    always @(state, satp, pte, virt_bus.a_valid, virt_bus.d_ready, phy_bus.d_valid, tlb_hit, invalid) begin
        case (state)
            S_IDLE: begin
                if (~invalid & paging & virt_bus.a_valid) begin
                    next_state = tlb_hit ? S_ADDR : S_PGD;
                end else begin
                    next_state = S_IDLE;
                end
            end
            S_PGD: begin
                if (invalid)
                    next_state = S_DATA;
                else
                    next_state = phy_bus.d_valid ? S_PGD_DATA : S_PGD;
            end
            S_PGD_DATA: begin
                if (invalid) begin
                    next_state = S_IDLE;
                end else if (except) begin
                    next_state = S_TRAP;
                end else if (leaf) begin
                    next_state = S_ADDR;
                end else if (branch) begin
                    next_state = S_PMD;
                end else begin
                    next_state = S_PGD_DATA;
                end
                /*
                $display($time,, "State: S_PGD_DATA: state(%0x,%0x) (%0x,%0x) %0x",
                         state, next_state, except, leaf, phy_bus.d_data);*/
            end
            S_PMD: begin
                if (invalid)
                    next_state = S_DATA;
                else
                    next_state = phy_bus.d_valid ? S_PMD_DATA : S_PMD;
            end
            S_PMD_DATA: begin
                /*
                $display($time,, "State: S_PMD_DATA: state(%0x) (%0x,%0x) %0x",
                         state, except, leaf, phy_bus.d_data);*/
                if (invalid) begin
                    next_state = S_IDLE;
                end else if (except) begin
                    next_state = S_TRAP;
                end else if (leaf) begin
                    next_state = S_ADDR;
                end else if (branch) begin
                    next_state = S_PT;
                end else begin
                    next_state = S_PMD_DATA;
                end
            end
            S_PT: begin
                if (invalid)
                    next_state = S_DATA;
                else
                    next_state = phy_bus.d_valid ? S_PT_DATA : S_PT;
            end
            S_PT_DATA: begin
                /*
                $display($time,, "State: S_PT: state(%0x) (%0x,%0x) %0x",
                         state, except, leaf, phy_bus.d_data);*/
                if (invalid) begin
                    next_state = S_IDLE;
                end else if (leaf) begin
                    next_state = S_ADDR;
                end else begin
                    next_state = S_TRAP;
                end
            end
            S_ADDR: begin
                if (invalid)
                    next_state = S_DATA;
                else
                    next_state = phy_bus.d_valid ? S_DATA : S_ADDR;
            end
            S_DATA: begin
                /*$display($time,, "State: S_DATA: state(%0x) %0x",
                         state, virt_bus.d_ready);*/
                next_state = (invalid | virt_bus.d_ready) ? S_IDLE : S_DATA;
            end
            S_TRAP: begin
                /*$display($time,, "State: S_TRAP", state);*/
                next_state = S_IDLE;
            end
            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            page_fault <= 1'b0;
            tval <= 64'b0;
            pte <= 64'b0;
            tlb_update <= `DISABLE;
            tlb_wdata <= 44'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (~invalid & paging & virt_bus.a_valid) begin
                        if (tlb_hit) begin
                            /* Prepare to look up data directly */
                            /*$display($time,, "tlb_hit: (%x: %x)",
                                     virt_bus.a_address, tlb_rdata);*/

                            a_opcode  <= virt_bus.a_opcode;
                            a_param   <= virt_bus.a_param;
                            a_size    <= virt_bus.a_size;
                            a_source  <= virt_bus.a_source;
                            a_address <= {tlb_rdata, virt_bus.a_address[11:0]};
                            a_mask    <= virt_bus.a_mask;
                            a_data    <= virt_bus.a_data;
                            a_corrupt <= virt_bus.a_corrupt;
                            a_valid   <= virt_bus.a_valid;
                        end else begin
                            /* Save virt_bus request */
                            /*$display($time,, "not tlb_hit: (%x:)",
                                     virt_bus.a_address);*/
                            ori_a_opcode  <= virt_bus.a_opcode;
                            ori_a_param   <= virt_bus.a_param;
                            ori_a_size    <= virt_bus.a_size;
                            ori_a_source  <= virt_bus.a_source;
                            ori_a_address <= virt_bus.a_address;
                            ori_a_mask    <= virt_bus.a_mask;
                            ori_a_data    <= virt_bus.a_data;
                            ori_a_corrupt <= virt_bus.a_corrupt;
                            ori_a_valid   <= virt_bus.a_valid;

                            /* Prepare to look up pgd */
                            a_opcode <= `TL_GET;
                            a_param <= 3'b0;
                            a_size <= 3;
                            a_source <= 4'b0000;
                            a_address <= {root_ppn, virt_bus.a_address[38:30],
                                        3'b0};
                            a_mask <= 8'hFF;
                            a_data <= 64'b0;
                            a_corrupt <= 1'b0;
                            a_valid <= `TRUE;
                        end
                    end
                end
                S_PGD: begin
                    /*
                    $display($time,, "S_PGD: %0x, %0x ori(%0x)",
                             a_address, root_ppn, ori_a_address);*/

                    if (~invalid) begin
                        if (phy_bus.a_ready)
                            a_valid <= `FALSE;

                        if (phy_bus.d_valid)
                            pte <= phy_bus.d_data;
                    end
                end
                S_PGD_DATA: begin
                    /*$display($time,, "S_PGD_DATA: pte(%0x,%0x) ori(%0x)",
                             pte, except, ori_a_address);*/
                    if (invalid) begin
                        ;
                    end else if (except) begin
                        page_fault <= `ENABLE;
                        tval <= ori_a_address;
                    end else if (branch) begin
                        /* Prepare to look up pmd */
                        a_address <= {pte[53:10], ori_a_address[29:21],
                                      3'b0};
                        a_valid <= `TRUE;
                    end else if (leaf) begin
                        /* Restore virt_bus request */
                        a_opcode  <= ori_a_opcode;
                        a_param   <= ori_a_param;
                        a_size    <= ori_a_size;
                        a_source  <= ori_a_source;
                        a_address <= {pte[53:28], ori_a_address[29:0]};
                        a_mask    <= ori_a_mask;
                        a_data    <= ori_a_data;
                        a_corrupt <= ori_a_corrupt;
                        a_valid   <= ori_a_valid;

                        tlb_wdata <= {pte[53:28], ori_a_address[29:12]};
                        tlb_update <= `ENABLE;
                    end
                end
                S_PMD: begin
                    /*$display($time,, "S_PMD: %0x, %0x ori(%0x)",
                             a_address, root_ppn, ori_a_address);*/

                    if (~invalid) begin
                        if (phy_bus.a_ready)
                            a_valid <= `FALSE;

                        if (phy_bus.d_valid)
                            pte <= phy_bus.d_data;
                    end
                end
                S_PMD_DATA: begin
                    /*$display($time,, "S_PMD_DATA: pte(%0x,%0x) ori(%0x)",
                             pte, except, ori_a_address);*/
                    if (invalid) begin
                        ;
                    end else if (except) begin
                        page_fault <= `ENABLE;
                        tval <= ori_a_address;
                    end else if (branch) begin
                        /* Prepare to look up pt */
                        a_address <= {pte[53:10], ori_a_address[20:12],
                                      3'b0};
                        a_valid <= `TRUE;
                    end else if (leaf) begin
                        /* Restore virt_bus request */
                        a_opcode  <= ori_a_opcode;
                        a_param   <= ori_a_param;
                        a_size    <= ori_a_size;
                        a_source  <= ori_a_source;
                        a_address <= {pte[53:19], ori_a_address[20:0]};
                        a_mask    <= ori_a_mask;
                        a_data    <= ori_a_data;
                        a_corrupt <= ori_a_corrupt;
                        a_valid   <= ori_a_valid;

                        tlb_wdata <= {pte[53:19], ori_a_address[20:12]};
                        tlb_update <= `ENABLE;
                    end
                end
                S_PT: begin
                    if (~invalid) begin
                        if (phy_bus.a_ready)
                            a_valid <= `FALSE;

                        if (phy_bus.d_valid)
                            pte <= phy_bus.d_data;
                    end
                end
                S_PT_DATA: begin
                    /*$display($time,, "S_PT: pte(%0x,%0x) ori(%0x)",
                             pte, except, ori_a_address);*/
                    if (invalid) begin
                        ;
                    end else if (except) begin
                        page_fault <= `ENABLE;
                        tval <= ori_a_address;
                    end else begin
                        /* Restore virt_bus request */
                        a_opcode  <= ori_a_opcode;
                        a_param   <= ori_a_param;
                        a_size    <= ori_a_size;
                        a_source  <= ori_a_source;
                        a_address <= {pte[53:10], ori_a_address[11:0]};
                        a_mask    <= ori_a_mask;
                        a_data    <= ori_a_data;
                        a_corrupt <= ori_a_corrupt;
                        a_valid   <= ori_a_valid;

                        tlb_wdata <= pte[53:10];
                        tlb_update <= `ENABLE;
                    end
                end
                S_ADDR: begin
                    /*$display($time,, "S_ADDR: (%0x:%0x)",
                             phy_bus.d_data, phy_bus.d_valid);*/
                    if (~invalid) begin
                        tlb_update <= `DISABLE;
                        tlb_wdata <= 44'b0;

                        if (phy_bus.a_ready) begin
                            a_valid <= `FALSE;
                            a_ready <= `TRUE;
                        end

                        if (phy_bus.d_valid) begin
                            d_opcode <= phy_bus.d_opcode;
                            d_param <= phy_bus.d_param;
                            d_size <= phy_bus.d_size;
                            d_source <= phy_bus.d_source;
                            d_sink <= phy_bus.d_sink;
                            d_denied <= phy_bus.d_denied;
                            d_data <= phy_bus.d_data;
                            d_corrupt <= phy_bus.d_corrupt;
                            d_valid <= phy_bus.d_valid;
                        end
                    end
                end
                S_DATA: begin
                    /*$display($time,, "S_DATA: %0x", d_data);*/
                    /* Clear all phy_bus reply */
                    d_opcode  <= 3'b0;
                    d_param   <= 2'b0;
                    d_size    <= 3'b0;
                    d_source  <= 4'b0;
                    d_sink    <= 6'b0;
                    d_denied  <= 1'b0;
                    d_data    <= 64'b0;
                    d_corrupt <= 1'b0;
                    d_valid   <= 1'b0;
                    a_ready   <= 1'b0;

                    a_opcode  <= 3'b0;
                    a_param   <= 3'b0;
                    a_size    <= 3'b0;
                    a_source  <= 4'b0;
                    a_address <= 64'b0;
                    a_mask    <= 8'b0;
                    a_data    <= 64'b0;
                    a_corrupt <= 1'b0;
                    a_valid   <= 1'b0;
                    a_ready   <= 1'b0;

                    ori_a_address <= 64'b0;
                end
                S_TRAP: begin
                    page_fault <= `DISABLE;
                    tval <= 64'b0;
                    ori_a_address <= 64'b0;
                end
                default: begin
                end
            endcase
        end
    end

    dbg_mmu u_dbg_mmu (
    	.clk        (clk        ),
        .rst_n      (rst_n      ),
        .pc         (pc         ),
        .state      (state      ),
        .next_state (next_state ),
        .addr       (ori_a_address),
        .pte        (pte        ),
        .invalid    (invalid    ),
        .tlb_hit    (tlb_hit    )
    );

endmodule
