`timescale 1ns / 1ps

`include "isa.vh"

module dbg_ram (
    input wire clk,
    input wire rst_n,

    input wire [63:0] mask,

    tilelink.slave bus
);

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else if (`CHECK_ENV("VERBOSE_RAM")) begin
            if (bus.a_valid) begin
                if (bus.a_opcode == `TL_GET)
                    $display($time,, "RAM(get): [%x]", bus.a_address);
                else if (bus.a_opcode == `TL_PUT_F || bus.a_opcode == `TL_PUT_P)
                    $display($time,, "RAM(put): [%x] %x (%x:%x)",
                             bus.a_address, bus.a_data, bus.a_mask, bus.a_size);
                else
                    $display($time,, "RAM(unknown): [%x] %x",
                             bus.a_address, bus.a_data);
            end

            if (bus.d_valid & (bus.d_opcode == `TL_ACCESS_ACK_DATA))
                $display($time,, "RAM(data): %x", bus.d_data);
        end
    end

endmodule
