`timescale 1ns/1ps

`include "isa.vh"

module tb_instcache;

    wire clk;
    wire rst_n;

    wire [63:0] pc;
    wire inst_valid;
    wire inst_comp;
    wire [31:0] inst;
    wire request;

    tilelink bus();

    clk_rst u_clk_rst (
        .clk   (clk  ),
        .rst_n (rst_n)
    );

    rom u_rom (
        .clk   (clk  ),
        .rst_n (rst_n),
        .bus   (bus  )
    );

    instcache u_instcache (
        .clk        (clk       ),
        .rst_n      (rst_n     ),
        .pc         (pc        ),
        .inst_valid (inst_valid),
        .inst_comp  (inst_comp ),
        .inst       (inst      ),
        .request    (request   ),
        .bus        (bus       )
    );

    stimulator u_stimulator (
        .clk        (clk        ),
        .rst_n      (rst_n      ),
        .pc         (pc         ),
        .inst_valid (inst_valid ),
        .inst_comp  (inst_comp  ),
        .inst       (inst       ),
        .request    (request    )
    );

    always @(posedge clk, negedge rst_n) begin
        if (inst_valid)
            $display($time,, "inst: %x(%x,%x); pc: %x; req: %x",
                     inst, inst_valid, inst_comp, pc, request);
    end

    initial begin
        #1024 $finish();
    end

endmodule
