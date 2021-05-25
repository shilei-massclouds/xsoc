`timescale 1ns / 1ps

`include "isa.vh"

module stimulator (
    input wire clk,
    input wire rst_n,

    tilelink.master bus
);

    localparam UART_RX_FIFO = 4'h0; /* In:  Recieve Buffer Register */
    localparam UART_TX_FIFO = 4'h4; /* Out: Transmitter Holding Register */
    localparam UART_STATUS  = 4'h8; /* In:  Line Status Register */
    localparam UART_CONTROL = 4'hc; /* Out: Line Control Register */

    localparam S_IDLE = 2'b00;
    localparam S_ADDR = 2'b01;
    localparam S_WAIT = 2'b10;

    reg  valid;
    reg  [7:0]  data;
    reg  [63:0] addr;
    reg  [1:0] stage;

    /* Generator */
    logic [1:0] state, next_state;
    dff #(2, 2'b00) dff_state(clk, rst_n, `DISABLE, `DISABLE,
                              next_state, state);

    assign bus.a_opcode  = `TL_GET;
    assign bus.a_param   = 3'b0;
    assign bus.a_size    = 3'd3;
    assign bus.a_source  = 4'b0001;
    assign bus.a_mask    = 8'hFF;
    assign bus.a_corrupt = `FALSE;
    assign bus.a_data = data;

    assign bus.a_valid = (state == S_ADDR);
    assign bus.d_ready = `ENABLE;

    always @(state, valid, bus.a_ready, bus.d_valid) begin
        case (state)
            S_IDLE:
                next_state = valid ? S_ADDR : S_IDLE;
            S_ADDR:
                next_state = bus.a_ready ? S_WAIT : S_ADDR;
            S_WAIT:
                next_state = bus.d_valid ? S_IDLE : S_WAIT;
            default:
                next_state = S_IDLE;
        endcase
    end

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            bus.a_address <= 64'b0;
        end else begin
            if (state == S_IDLE && valid) begin
                bus.a_address <= addr;
            end

            if (state == S_ADDR && bus.a_ready)
                bus.a_address <= 64'b0;

            if (state == S_WAIT && bus.d_valid) begin
                if (addr == UART_RX_FIFO)
                    $display($time,, "RX: d_data (%x)", bus.d_data);
                if (addr == UART_STATUS)
                    $display($time,, "STATUS: d_data (%x)", bus.d_data);
            end
        end
    end

    reg [7:0] in_char;
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            stage <= 2'b0;
            valid <= `ENABLE;
            addr  <= UART_STATUS;
            data  <= 8'b0;
            in_char <= "A";
        end else begin
            if (bus.d_valid) begin
                case (stage)
                    2'b00: begin
                        addr <= UART_CONTROL;
                        data <= 8'h3;
                    end
                    2'b01: begin
                        addr <= UART_STATUS;
                        data <= 8'b0;
                    end
                    2'b10: begin
                        addr <= UART_TX_FIFO;
                        data <= in_char;
                        if (in_char == "\n")
                            in_char <= "A";
                        else if (in_char >= "C")
                            in_char <= "\n";
                        else
                            in_char <= in_char + 1;
                    end
                    2'b11: begin
                        addr <= UART_RX_FIFO;
                        data <= 8'b0;
                    end
                endcase
                valid <= `ENABLE;
                stage <= stage + 1;
            end else begin
                valid <= `DISABLE;
            end
        end
    end

    initial begin
        #20480 $finish();
    end

endmodule

