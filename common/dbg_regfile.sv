`timescale 1ns / 1ps

`include "isa.vh"

module dbg_regfile (
    input wire clk,
    input wire rst_n,

    input wire [63:0] pc,
    input wire [4:0]  rd,
    input wire [63:0] data
);

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            if (rd) begin
                string test = getenv("TEST");
                case (test)
                    "tests/calc_add": begin
                        assert((pc == 'h1004) -> (rd == 7 && data == 8));
                    end
                    "tests/mem_sw_lw": begin
                        assert((pc == 'h1014) ->
                               (rd == 10 && data == 'h0a0b0c0d01020304));
                    end
                    "tests/bj_ge": begin
                        assert((pc == 'h100c) -> (rd == 7 && data == 'h2));
                    end
                    "tests/j": begin
                        assert((pc == 'h1008) -> (rd == 7 && data == 'h2));
                    end
                    "tests/rom_load": begin
                        assert((pc == 'h1008) ->
                               (rd == 6 && data == 'ha0b0c0d0e0f01020));
                        assert((pc == 'h100c) ->
                               (rd == 7 && data == 'hffffffffe0f01020));
                        assert((pc == 'h1010) -> (rd == 28 && data == 'h1020));
                        assert((pc == 'h1014) -> (rd == 29 && data == 'h20));
                    end
                endcase

                if (getenv("VERBOSE_REG").len() > 0 || check_verbose(pc)) begin
                    $display($time,, "Reg: [%08x] %0x => %s(%0d)",
                             pc, data, abi_names[rd], rd);
                end
            end
        end
    end

endmodule
