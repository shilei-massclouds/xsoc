`timescale 1ns/1ps

`include "isa.vh"

module rom_rd (
    input  wire clk,
    input  wire rst_n,

    /* TileLink Side */
    output wire valid,
    output wire [63:0] data,
    input  wire ready,

    /* Fifo Side */
    input  wire almost_empty,
    output wire rd_en,
    input  wire [7:0] din
);

    localparam S_IDLE = 2'b00;
    localparam S_DATA = 2'b01;
    localparam S_DONE = 2'b10;

    reg  can_read;
    reg  [2:0] offset;
    reg  [63:0] buffer;

    wire [1:0] state;
    reg  [1:0] next_state;
    dff #(2, 2'b0) dff_state(clk, rst_n, `DISABLE, `DISABLE, next_state, state);

    assign rd_en = can_read;
    assign valid = (state == S_DONE);
    assign data = (state == S_DONE) ? buffer : 64'b0;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            can_read <= `DISABLE;
        end else begin
            can_read <= ~almost_empty;
        end
    end

    always @(state, can_read, offset, ready) begin
        case (state)
            S_IDLE:
                next_state = can_read ? S_DATA : S_IDLE;
            S_DATA:
                next_state = &offset ? S_DONE :
                             can_read ? S_DATA : S_IDLE;
            S_DONE:
                next_state = ready ? S_IDLE : S_DONE;
            default:
                next_state = S_IDLE;
        endcase
    end

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            offset <= 3'b0;
        end else begin
            if (state == S_DATA) begin
                offset <= offset + 3'b1;
                buffer <= {din, buffer[63:8]};
            end
        end
    end

endmodule