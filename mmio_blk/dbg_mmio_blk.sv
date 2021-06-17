`timescale 1ns / 1ps

`include "isa.vh"

module dbg_mmio_blk (
    input wire clk,
    input wire rst_n,

    tilelink.slave bus
);

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else if (`CHECK_ENV("VERBOSE_BLK")) begin
            if (bus.a_valid) begin
                if (bus.a_opcode == `TL_GET)
                    $display($time,, "BLK(get): [%x] (%x);",
                             bus.a_address, bus.a_size);
                else if (bus.a_opcode == `TL_PUT_F || bus.a_opcode == `TL_PUT_P)
                    $display($time,, "BLK(put): [%x] %x (%x:%x)",
                             bus.a_address, bus.a_data, bus.a_mask, bus.a_size);
                else
                    $display($time,, "BLK(unknown): [%x] %x",
                             bus.a_address, bus.a_data);
            end

            if (bus.d_valid & (bus.d_opcode == `TL_ACCESS_ACK_DATA))
                $display($time,, "BLK(data): %x", bus.d_data);
        end
    end

endmodule
