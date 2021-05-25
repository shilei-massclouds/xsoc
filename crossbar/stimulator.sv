`timescale 1ns / 1ps

`include "isa.vh"

module stimulator (
    input  wire         clk,
    input  wire         rst_n,

    output reg  [15:0]  request,
    input  wire [15:0]  grant,

    tilelink.master     master[16]
);

    integer m0_stage;
    integer m1_stage;

    initial begin
        m0_stage = 0;
        m1_stage = 0;
        #10 write_req(0, master[0], 64'habcd, 64'h8000_0410, 8);
        #20 write_req(1, master[1], 64'h1234, 64'h8000_0400, 8);
        request = 16'b11;
    end

    always @(posedge clk) begin
        if (rst_n) begin
            if (~request[0]) begin
                case (m0_stage)
                0: write_req(0, master[0], 64'h0201, 64'h8000_0418, 8);
                1: read_req(0, master[0], 64'h8000_0410, 8);
                2: read_req(0, master[0], 64'h0000_0400, 8);
                3: read_req(0, master[0], 64'h1000, 8);
                default: m0_stage <= 0;
                endcase

                request[0] <= 1'b1;
                m0_stage ++;
            end

            if (~request[1]) begin
                case (m1_stage)
                0: write_req(1, master[1], 64'h4567, 64'h8000_0408, 8);
                1: read_req(1, master[1], 64'h8000_0400, 8);
                2: read_req(1, master[1], 64'h8000_0410, 8);
                3: read_req(1, master[1], 64'h1008, 8);
                default: m1_stage <= 0;
                endcase

                request[1] <= 1'b1;
                m1_stage ++;
            end
        end
    end

    assign master[0].d_ready = `ENABLE;
    assign master[1].d_ready = `ENABLE;
    always @(posedge clk) begin
        if (~rst_n) begin
        end else begin
            if (master[0].d_valid) begin
                master[0].a_valid <= `DISABLE;
                request[0] <= 1'b0;
                ack(master[0], 0);
            end

            if (master[1].d_valid) begin
                master[1].a_valid <= `DISABLE;
                request[1] <= 1'b0;
                ack(master[1], 1);
            end
        end
    end

    /* Functions */
    function write_req(
        input integer source,
        virtual tilelink.master bus,
        input [63:0] data,
        input [63:0] addr,
        input [3:0] size
    );

        $display($time,, "%2x: [%x] Write req %x (%1d)...",
                 source, addr, data, size);

        bus.a_opcode = `TL_PUT_F;
        bus.a_size = $clog2(size);
        bus.a_source = source;
        bus.a_address = addr;
        bus.a_mask = 8'hFF;
        bus.a_data = data;
        bus.a_valid = `ENABLE;

    endfunction

    function read_req(
        input integer source,
        virtual tilelink.master bus,
        input [63:0] addr,
        input [3:0] size
    );

        $display($time,, "%2x: [%x] Read req (%1d)...",
                 source, addr, size);

        bus.a_opcode = `TL_GET;
        bus.a_size = $clog2(size);
        bus.a_source = source;
        bus.a_address = addr;
        bus.a_mask = 8'hFF;
        bus.a_valid = `ENABLE;

    endfunction

    function ack(virtual tilelink.master bus, input integer source);
        if (bus.d_opcode == `TL_ACCESS_ACK_DATA)
            $display($time,, "%2x: [%x] Read (%1d) %x Ack!",
                     source, bus.a_address, 1 << bus.d_size, bus.d_data);
        else
            $display($time,, "%2x: [%x] Write Ack!", source, bus.a_address);
    endfunction

    initial begin
        #5000 $finish();
    end

    generate
        for (genvar i = 0; i < 16; i++) begin: cycle0
            initial request[i] = `DISABLE;
        end
    endgenerate

endmodule
