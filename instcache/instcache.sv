`timescale 1ns / 1ps

`include "isa.vh"

module instcache (
    input   wire    clk,
    input   wire    rst_n,

    input   wire    invalid,
    input   wire    page_fault,

    input   wire    [63:0] pc,

    output  wire    inst_valid,
    output  wire    inst_comp,
    output  wire    [31:0] inst,

    output  reg     request,
    tilelink.master bus
);

    /*
     * Address space of instruction is within 2^32, so only
     * low-32-bit part is valid.
     * PC := {pad(32), tag(24), index(5), offset(3)};
     */
    wire [23:0] tag    = pc[31:8];
    wire [4:0]  index  = pc[7:3];
    wire [2:0]  offset = pc[2:0];

    /*
     * Internal cache line:
     * Fields := {valid(1), tag(24), data(64)};
     */
    `define F_DATA  63:0
    `define F_TAG   87:64
    `define F_VALID 88

    localparam CACHE_WIDTH = 1 + 24 + 64;   /* bits */
    localparam CACHE_DEPTH = 32;            /* index: 2^5 */

    bit [(CACHE_WIDTH-1):0] lines[CACHE_DEPTH];
    reg [1:0]               req_bmp;
    reg [63:0]              req_addr;
    wire [63:0]             req_addr_rest;

    wire hit = lines[index][`F_VALID] & (lines[index][`F_TAG] == tag);
    wire [63:0] data = lines[index][`F_DATA];

    wire crossed = (offset == 6) & data[49] & data[48];

    /* Back half of the instruction if it crosses the boundary. */
    wire [31:0] bh_pc    = {(pc[31:3] + 1), 3'b0};
    wire [23:0] bh_tag   = bh_pc[31:8];
    wire [4:0]  bh_index = bh_pc[7:3];
    wire [63:0] bh_data  = lines[bh_index][`F_DATA];

    wire hit_rest = lines[bh_index][`F_VALID] &
                    (lines[bh_index][`F_TAG] == bh_tag);

    wire last_req = ^req_bmp;

    /* Output */
    assign inst_valid = ~invalid &
                        ((~crossed & hit) | (crossed & (hit & hit_rest)));
    assign inst = inst_valid ?
        (({32{~crossed}} & (data >> (offset * 8))) |
         ({32{crossed}} & {bh_data[15:0], data[63:48]})) : {31'b0, 1'b1};
    assign inst_comp  = ~(&(inst[1:0]));

    /* Controller */
    localparam S_CACHE = 2'b00;
    localparam S_ADDR  = 2'b01;
    localparam S_DATA  = 2'b10;

    logic [1:0] state, next_state;
    dff #(2, 2'b0) dff_state(clk, rst_n, `DISABLE, `DISABLE, next_state, state);

    /* State transition */
    always @(state, crossed, hit, hit_rest, page_fault,
             bus.a_ready, bus.d_valid, last_req, invalid) begin

        case (state)
            S_CACHE: begin
                if (invalid) begin
                    next_state = S_CACHE;
                end else begin
                    if (crossed) begin
                        next_state = (hit & hit_rest) ? S_CACHE : S_ADDR;
                    end else begin
                        next_state = hit ? S_CACHE : S_ADDR;
                    end
                end
            end
            S_ADDR:
                next_state = (invalid | page_fault) ? S_CACHE :
                             bus.a_ready ? S_DATA : S_ADDR;
            S_DATA:
                if (invalid) begin
                    next_state = S_CACHE;
                end else if (bus.d_valid) begin
                    next_state = last_req ? S_CACHE : S_ADDR;
                end else begin
                    next_state = S_DATA;
                end
            default:
                next_state = S_CACHE;
        endcase
    end

    /* Operations for datapath */
    reg set_addr0;
    reg set_addr1;
    reg fillin;
    reg clr_all;
    reg clr_addr0;

    always @(state, crossed, hit, hit_rest, page_fault,
             bus.a_ready, bus.d_valid, last_req, invalid) begin

        set_addr0 = `DISABLE;
        set_addr1 = `DISABLE;
        fillin    = `DISABLE;
        clr_all   = `DISABLE;
        clr_addr0 = `DISABLE;

        case (state)
            S_CACHE: begin
                request = `DISABLE;

                if (~invalid) begin
                    if (crossed) begin
                        if (~hit) set_addr0 = `ENABLE;
                        if (~hit_rest) set_addr1 = `ENABLE;
                    end else if (~hit) begin
                        set_addr0 = `ENABLE;
                    end
                end
            end
            S_ADDR: begin
                if (invalid | page_fault)
                    clr_all = `ENABLE;
                else
                    request = `ENABLE;
            end
            S_DATA: begin
                if (invalid) begin
                    clr_all = `ENABLE;
                end else if (bus.d_valid) begin
                    fillin = `ENABLE;
                    if (last_req)
                        clr_all = `ENABLE;
                    else
                        clr_addr0 = `ENABLE;
                end
            end
        endcase
    end

    /* Datapath */
    assign req_addr_rest = req_addr + 8;
    assign bus.a_valid   = (state == S_ADDR) & ~page_fault;
    assign bus.a_address = req_bmp[0] ? req_addr :
                           req_bmp[1] ? req_addr_rest : 64'b0;
    assign bus.d_ready  = `TRUE;
    assign bus.a_opcode = `TL_GET;
    assign bus.a_size = 3;
    assign bus.a_source = 4'b0000;
    assign bus.a_mask = 8'hFF;

    always @(posedge clk, negedge rst_n) begin

        if (~rst_n) begin
            req_addr <= 64'b0;
            req_bmp <= 2'b0;
            request <= `DISABLE;
        end else begin
            if (invalid) begin
                for (integer i = 0; i < CACHE_DEPTH; i++) begin
                    lines[i] <= {CACHE_WIDTH{1'b0}};
                end
            end

            if (set_addr0 | set_addr1) begin
                req_addr <= {pc[63:3], 3'b0};
                req_bmp[0] <= set_addr0;
                req_bmp[1] <= set_addr1;
            end

            if (fillin) begin
                if (req_bmp[0]) begin
                    lines[req_addr[7:3]] <= {1'b1, req_addr[31:8], bus.d_data};
                end else if (req_bmp[1]) begin
                    lines[req_addr_rest[7:3]] <=
                        {1'b1, req_addr_rest[31:8], bus.d_data};
                end
            end

            if (clr_addr0) begin
                req_bmp[0] <= 1'b0;
            end

            if (clr_all) begin
                req_addr <= 64'b0;
                req_bmp <= 2'b0;
            end
        end
    end

    dbg_instcache u_dbg_instcache (
    	.clk        (clk            ),
        .rst_n      (rst_n          ),
        .pc         (pc             ),
        .state      (state          ),
        .line       (lines[index]   ),
        .bh_line    (lines[bh_index]),
        .req_bmp    (req_bmp        ),
        .inst_valid (inst_valid     ),
        .inst_comp  (inst_comp      ),
        .inst       (inst           ),
        .page_fault (page_fault     ),
        .invalid    (invalid        ),
        .request    (request        ),
        .bus        (bus            )
    );

    initial begin
        //$monitor($time,, "data(%x) inst(%x) offset(%x)", data, inst, offset);
    end

endmodule
