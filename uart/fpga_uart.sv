`timescale 1ns / 1ps

`include "isa.vh"

import "DPI-C" function longint
uart_putc(input byte base);

module uart (
    input   wire    clk,
    input   wire    rst_n,

    tilelink.slave  bus
);

    localparam UART_RX_FIFO = 4'h0; /* In:  Recieve Buffer Register */
    localparam UART_TX_FIFO = 4'h4; /* Out: Transmitter Holding Register */
    localparam UART_STATUS  = 4'h8; /* In:  Line Status Register */
    localparam UART_CONTROL = 4'hc; /* Out: Line Control Register */

    //                          Status Register
    // +--------+------+------+------+-------+-------+--------+-------+--------+
    // |  31:8  |  7   |  6   |  5   |   4   |   3   |   2    |   1   |   0    |
    // +--------+------+------+------+-------+-------+--------+-------+--------+
    //  Reserved   PE     FE     OE   Intr-En Tx-Full Tx-Empty Rx-Full Rx-Valid
    //
    //  PE: Parity Error;   FE: Frame Error;    OE: Overrun Error;
    //

    //                          Control Register
    //  +———————————+—————————————+———————————+——————————————+——————————————+
    //  | 31:5      |     4       |  3:2      |      1       |      0       |
    //  +———————————+—————————————+———————————+——————————————+——————————————+
    //    Reserved    Enable Intr   Reserved    Rst Rx FIFO    Rst Tx FIFO
    //


    localparam S_IDLE = 1'b0;
    localparam S_BUSY = 1'b1;

    reg [31:0] rx_buffer;
    reg [31:0] status;
    reg [31:0] control;

    reg do_rx;
    reg do_status;

    /* Controller */
    logic state, next_state;
    dff dff_stage(clk, rst_n, `DISABLE, `DISABLE, next_state, state);

    assign bus.a_ready = (state == S_IDLE);
    assign bus.d_valid = (state == S_BUSY);
    assign bus.d_data = ({32{do_rx}} & rx_buffer) |
                        ({32{do_status}} & status);

    /* State transition */
    always @(state, bus.a_valid, bus.d_ready) begin
        case (state)
            S_IDLE:
                next_state = bus.a_valid ? S_BUSY : S_IDLE;
            S_BUSY:
                next_state = bus.d_ready ? S_IDLE : S_BUSY;
            default:
                next_state = S_IDLE;
        endcase
    end

    /* Datapath */
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            rx_buffer <= 32'b0;
            status <= 32'h4;
            control <= 32'b0;
            do_rx <= `FALSE;
            do_status <= `FALSE;
        end else begin
            if ((state == S_IDLE) & bus.a_valid) begin
                $display($time,, "Uart: addr(%x)", bus.a_address);
                if (bus.a_address == UART_RX_FIFO) begin
                    do_rx <= `TRUE;
                end else if (bus.a_address == UART_TX_FIFO) begin
                    uart_putc(bus.a_data[7:0]);
                end else if (bus.a_address == UART_STATUS) begin
                    do_status <= `TRUE;
                end else if (bus.a_address == UART_CONTROL) begin
                    control <= bus.a_data[31:0];
                    $display($time,, "Control: %0x", bus.a_data[31:0]);
                end
            end

            if ((state == S_BUSY) & bus.d_ready) begin
                do_rx <= `FALSE;
                do_status <= `FALSE;
            end
        end
    end

endmodule

