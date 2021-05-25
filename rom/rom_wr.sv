`timescale 1ns/1ps

`include "isa.vh"

module rom_wr (
    input  wire clk,
    input  wire rst_n,

    /* TileLink Side */
    input  wire valid,
    output wire ready,
    input  wire [63:0] addr,

    /* Fifo Side */
    input  wire almost_full,
    output wire wr_en,
    output wire [7:0] dout
);

    localparam S_IDLE = 2'b00;
    localparam S_ADDR = 2'b01;
    localparam S_SEND = 2'b10;

    reg  [2:0] offset;
    reg [63:0] buffer;

    wire [1:0] state;
    reg  [1:0] next_state;
    dff #(2, 2'b0) dff_state(clk, rst_n, `DISABLE, `DISABLE, next_state, state);

    assign ready = (state == S_IDLE);
    assign wr_en = (state == S_SEND);
    assign dout  = (state == S_SEND) ? buffer[7:0] : 8'b0;

    always @(state, valid, almost_full, offset) begin
        case (state)
            S_IDLE:
                next_state = valid ? S_ADDR : S_IDLE;
            S_ADDR:
                next_state = almost_full ? S_ADDR : S_SEND;
            S_SEND:
                next_state = &offset ? S_IDLE :
                             almost_full ? S_ADDR : S_SEND;
            default:
                next_state = S_IDLE;
        endcase
    end

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            offset <= 3'b0;
            buffer <= 64'b0;
        end else begin
            if (state == S_IDLE && valid)
                buffer <= addr;

            if (state == S_SEND) begin
                offset <= offset + 3'b1;
                buffer <= {8'b0, buffer[63:8]};
            end
        end
    end

    initial begin
        /*
        $monitor($time,, "(%x): valid(%x) offset(%x) addr(%x)",
                 state, valid, offset, buffer);
                 */
    end

endmodule