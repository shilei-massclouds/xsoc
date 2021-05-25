`timescale 1ns/1ps

`include "isa.vh"

module tb_fetch;

    wire clk;
    wire rst_n;

    wire [63:0] pc;
    wire inst_valid;
    wire inst_compressed;
    wire [31:0] inst;
    wire request;

    reg  stall;
    reg  clear;
    reg  trap_en;
    reg  [63:0] trap_pc;
    reg  bj_en;
    reg  [63:0] bj_pc;

    assign stall = `DISABLE;
    assign clear = `DISABLE;
    assign trap_en = `DISABLE;
    assign trap_pc = 64'b0;
    assign bj_en = `DISABLE;
    assign bj_pc = 64'b0;

    tilelink bus();

    clk_rst u_clk_rst (
        .clk   (clk   ),
        .rst_n (rst_n )
    );

    rom u_rom (
        .clk   (clk   ),
        .rst_n (rst_n ),
        .bus   (bus)
    );

    fetch u_fetch (
        .clk     (clk     ),
        .rst_n   (rst_n   ),
        .stall   (stall   ),
        .clear   (clear   ),
        .trap_en (trap_en ),
        .trap_pc (trap_pc ),
        .bj_en   (bj_en   ),
        .bj_pc   (bj_pc   ),
        .inst    (inst    ),
        .pc      (pc      ),
        .request (request ),
        .bus     (bus)
    );

    initial begin
        $monitor($time,, "[%x]: %x", pc, inst);
        #1024 $finish();
    end

endmodule
