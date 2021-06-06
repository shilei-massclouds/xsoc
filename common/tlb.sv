`timescale 1ns / 1ps

`include "isa.vh"

module tlb (
    input   wire    clk,
    input   wire    rst_n,

    input   wire    invalid,

    input   wire    [26:0] if_addr,
    output  wire    [43:0] if_rdata,
    output  wire    if_hit,
    input   wire    [43:0] if_wdata,
    input   wire    if_update,

    input   wire    [26:0] ma_addr,
    output  wire    [43:0] ma_rdata,
    output  wire    ma_hit,
    input   wire    [43:0] ma_wdata,
    input   wire    ma_update
);

    /*
     * Construction of Virtual Address Space:
     * ADDR := {tag(22), index(5)};
     */
    wire [21:0] if_tag   = if_addr[26:5];
    wire [4:0]  if_index = if_addr[4:0];

    wire [21:0] ma_tag   = ma_addr[26:5];
    wire [4:0]  ma_index = ma_addr[4:0];

    /*
     * Internal cache line:
     * Fields := {valid(1), tag(22), data(44)};
     */
    `define F_TLB_DATA  43:0
    `define F_TLB_TAG   65:44
    `define F_TLB_VALID 66

    localparam CACHE_WIDTH = 1 + 22 + 44;   /* bits */
    localparam CACHE_DEPTH = 32;            /* index: 2^5 */

    bit [(CACHE_WIDTH-1):0] lines[CACHE_DEPTH];

    /* Output */
    assign if_hit = ~invalid &
                    lines[if_index][`F_TLB_VALID] &
                    (lines[if_index][`F_TLB_TAG] == if_tag);

    assign if_rdata = if_hit ? lines[if_index][`F_TLB_DATA] : 44'b0;

    assign ma_hit = ~invalid &
                    lines[ma_index][`F_TLB_VALID] &
                    (lines[ma_index][`F_TLB_TAG] == ma_tag);

    assign ma_rdata = ma_hit ? lines[ma_index][`F_TLB_DATA] : 44'b0;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            if (invalid) begin
                for (integer i = 0; i < CACHE_DEPTH; i++) begin
                    lines[i] <= {CACHE_WIDTH{1'b0}};
                end
            end else begin
                assert (~(if_update & ma_update));

                if (if_update)
                    lines[if_index] <= {1'b1, if_tag, if_wdata};

                if (ma_update)
                    lines[ma_index] <= {1'b1, ma_tag, ma_wdata};
            end
        end
    end

endmodule
