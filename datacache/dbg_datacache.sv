`timescale 1ns / 1ps

`include "isa.vh"

module dbg_datacache (
    input wire clk,
    input wire rst_n,

    input wire [63:0] pc,
    input wire [120:0] line,

    input wire hit,
    input wire [63:0] data,

    input wire update,
    input wire [63:0] update_data
);

    integer hit_count = 0;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            if (check_verbose(pc)) begin
                $display($time,, "datacache: line(%x) (%x:%x)",
                        line, hit, data);

                if (update)
                    $display($time,, "update: %x", update_data);

                if (hit) begin
                    hit_count <= hit_count + 1;
                    if (hit_count % 'h10000 == 0)
                        $display("hit count (%d)", hit_count);
                end
            end
        end
    end

endmodule
