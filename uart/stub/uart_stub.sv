`timescale 1ns / 1ps

`include "isa.vh"

import "DPI-C" function longint
uart_putc(input byte base);

module uart (
    input   wire    clk,
    input   wire    rst_n,

    tilelink.slave  bus
);

    localparam UART_LSR_THRE = 8'b00100000; /* Transmit-hold-register empty */
    localparam UART_LSR_TEMT = 8'b01000000; /* Transmitter empty */

    localparam UART_RBR = 0; /* In:  Recieve Buffer Register */
    localparam UART_THR = 0; /* Out: Transmitter Holding Register */
    localparam UART_DLL = 0; /* Out: Divisor Latch Low */
    localparam UART_IER = 1; /* I/O: Interrupt Enable Register */
    localparam UART_DLM = 1; /* Out: Divisor Latch High */
    localparam UART_FCR = 2; /* Out: FIFO Control Register */
    localparam UART_IIR = 2; /* I/O: Interrupt Identification Register */
    localparam UART_LCR = 3; /* Out: Line Control Register */
    localparam UART_MCR = 4; /* Out: Modem Control Register */
    localparam UART_LSR = 5; /* In:  Line Status Register */
    localparam UART_MSR = 6; /* In:  Modem Status Register */
    localparam UART_SCR = 7; /* I/O: Scratch Register */

    localparam S_IDLE = 1'b0;
    localparam S_BUSY = 1'b1;

    reg [7:0] lsr;

    reg read_lsr;

    /* Controller */
    logic state, next_state;
    dff dff_state (clk, rst_n, `DISABLE, `DISABLE, next_state, state);

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
    assign bus.a_ready = (state == S_IDLE);
    assign bus.d_valid = (state == S_BUSY);
    assign bus.d_data  = {56'b0, {8{read_lsr}} & lsr};
    assign bus.d_denied = `DISABLE;
    /* The d_param indicates whether cached. */
    /* Uart has no cache. */
    assign bus.d_param = 2'b01;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            lsr <= UART_LSR_THRE | UART_LSR_TEMT;
            read_lsr <= `FALSE;
        end else begin
            if ((state == S_IDLE) & bus.a_valid) begin
                if (bus.a_address != UART_THR && bus.a_address != UART_LSR)
                    $display($time,, "Uart: addr(%x)", bus.a_address);

                if (bus.a_opcode == `TL_PUT_F) begin
                    if (bus.a_address == UART_THR) begin
                        uart_putc(bus.a_data[7:0]);
                    end
                    bus.d_opcode <= `TL_ACCESS_ACK;
                end else if (bus.a_opcode == `TL_GET) begin
                    if (bus.a_address == UART_LSR) begin
                        read_lsr <= `TRUE;
                    end
                    bus.d_opcode <= `TL_ACCESS_ACK_DATA;
                end
                bus.d_size <= bus.a_size;
                bus.d_source <= bus.a_source;
            end

            if ((state == S_BUSY) & bus.d_ready) begin
                read_lsr <= `FALSE;
                //do_rx <= `FALSE;
                //do_status <= `FALSE;
            end
        end
    end

endmodule
