`timescale 1ns / 1ps

`include "isa.vh"

module crossbar_ctl (
    input  wire clk,
    input  wire rst_n,

    input  wire [15:0] request,
    input  wire [15:0] grant,

    output reg  set_owner,
    output reg  clr_owner
);

    localparam S_IDLE = 1'b0;
    localparam S_BUSY = 1'b1;

    /* Controller */
    logic state, next_state;
    dff dff_state (clk, rst_n, `DISABLE, `DISABLE, next_state, state);

    wire request_valid = |request;

    /* State transition */
    always @(state, request, grant) begin
        case (state)
            S_IDLE:
                next_state = request_valid ? S_BUSY : S_IDLE;
            S_BUSY:
                next_state = ~(|(grant & request)) ? S_IDLE : S_BUSY;
            default:
                next_state = S_IDLE;
        endcase
    end

    /* Operations */
    always @(state, request, grant) begin
        set_owner = `DISABLE;
        clr_owner = `DISABLE;
        case (state)
            S_IDLE:
                if (request_valid) set_owner = `ENABLE;
            S_BUSY:
                if (~(|(grant & request))) clr_owner = `ENABLE;
        endcase
    end

endmodule
