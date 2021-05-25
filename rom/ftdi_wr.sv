`timescale 1ns / 1ps

module ftdi_wr (
    input  wire clk,
    input  wire rst_n,

    /* fifo side */
    input  wire empty,
    output wire rd_en,
    input  wire [7:0] din,

    /* ftdi side */
    input  wire txe_n,
    output wire wr_n,
    output wire siwu_n,
    output wire [7:0] dout
);

    localparam S_IDLE  = 2'b00;
    localparam S_RECV  = 2'b01;
    localparam S_WAIT  = 2'b10;
    localparam S_SEND  = 2'b11;

    wire [1:0] state;
    reg  [1:0] next_state;
    dff #(2, 2'b0) dff_state(clk, rst_n, 1'b0, 1'b0, next_state, state);

    assign siwu_n = 1'b1;

    assign rd_en = (state == S_RECV);
    assign wr_n = ~(state == S_SEND);
    assign dout = (state == S_SEND) ? din : 8'bz;

    always @(state, empty, txe_n) begin
        case (state)
            S_IDLE:
                next_state = empty ? S_IDLE : S_RECV;
            S_RECV:
                next_state = txe_n ? S_WAIT : S_SEND;
            S_WAIT:
                next_state = txe_n ? S_WAIT : S_SEND;
            S_SEND:
                next_state = empty ? S_IDLE : S_RECV;
            default:
                next_state = S_IDLE;
        endcase
    end

endmodule
