`timescale 1ns / 1ps

module ftdi_rd(
    input wire clk,
    input wire rst_n,

    /* ftdi side */
    input  wire rxf_n,
    output wire oe_n,
    output wire rd_n,
    input  wire [7:0] din,

    /* fifo side */
    input  wire full,
    output wire wr_en,
    output wire [7:0] dout
);

    localparam S_IDLE  = 3'b000;
    localparam S_OE    = 3'b001;
    localparam S_RD    = 3'b010;
    localparam S_GET   = 3'b011;
    localparam S_WR    = 3'b100;

    reg  [7:0] data;
    wire [2:0] state;
    reg  [2:0] next_state;
    dff #(3, 3'b0) dff_state(clk, rst_n, 1'b0, 1'b0, next_state, state);

    assign oe_n = ~((state == S_OE) || (state == S_RD));
    assign rd_n = ~(state == S_RD);
    assign wr_en = (state == S_WR);
    assign dout = data;

    always @(state, rxf_n, full) begin
        case (state)
            S_IDLE:
                next_state = rxf_n ? S_IDLE : S_OE;
            S_OE:
                next_state = S_RD;
            S_RD:
                next_state = S_GET;
            S_GET:
                next_state = full ? S_GET : S_WR;
            S_WR:
                next_state = S_IDLE;
            default:
                next_state = S_IDLE;
        endcase
    end

    reg set_data = 1'b0;
    always @(state, rxf_n, full) begin
        set_data = 1'b0;
        case (state)
            S_IDLE:
                ;
            S_OE:
                ;
            S_RD:
                set_data = 1'b1;
            S_GET:
                ;
            S_WR:
                ;
            default:
                set_data = 1'b0;
        endcase
    end

    always @(posedge clk, negedge rst_n) begin
       if (~rst_n) begin
           data <= 8'b0;
       end else begin
           if (set_data) data <= din;
       end
    end

endmodule
