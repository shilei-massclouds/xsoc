`timescale 1ns/1ps

`include "isa.vh"

module tb_ram;

    wire clk;
    wire rst_n;

    tilelink bus();

    clk_rst u_clk_rst(
    	.clk   (clk   ),
        .rst_n (rst_n )
    );

    ram u_ram(
        .clk   (clk   ),
        .rst_n (rst_n ),
        .bus   (bus   )
    );

    reg [63:0] data[4];

    initial begin
        data[0] = 64'h0706_0504_0302_0100;
        data[1] = 64'h0f0e_0d0c_0b0a_0908;
        data[2] = 64'ha7a6_a5a4_a3a2_a1a0;
        data[3] = 64'hafae_adac_abaa_a9a8;
    end

    assign bus.d_ready = `ENABLE;

    initial begin
        bus.a_valid = `DISABLE;
    end

    initial begin
        write_req(bus, data[0], 64'h400, 8);
        #20 write_req(bus, data[1][31:0], 64'h408, 4);
        #20 write_req(bus, data[1][63:32], 64'h40c, 4);
        #20 write_req(bus, data[2][15:0], 64'h410, 2);
        #20 write_req(bus, data[2][31:16], 64'h412, 2);
        #20 write_req(bus, data[2][47:32], 64'h414, 2);
        #20 write_req(bus, data[2][63:48], 64'h416, 2);
        #20 write_req(bus, data[3][7:0], 64'h418, 1);
        #20 write_req(bus, data[3][15:8], 64'h419, 1);
        #20 write_req(bus, data[3][23:16], 64'h41a, 1);
        #20 write_req(bus, data[3][31:24], 64'h41b, 1);
        #20 write_req(bus, data[3][39:32], 64'h41c, 1);
        #20 write_req(bus, data[3][47:40], 64'h41d, 1);
        #20 write_req(bus, data[3][55:48], 64'h41e, 1);
        #20 write_req(bus, data[3][63:56], 64'h41f, 1);
        #20 read_req(bus, 64'h400, 8);
        #20 read_req(bus, 64'h408, 8);
        #20 read_req(bus, 64'h410, 8);
        #20 read_req(bus, 64'h418, 8);
        #20 read_req(bus, 64'h410, 4);
        #20 read_req(bus, 64'h414, 4);
        #20 read_req(bus, 64'h418, 2);
        #20 read_req(bus, 64'h41a, 2);
        #20 read_req(bus, 64'h41c, 1);
        #20 read_req(bus, 64'h41d, 1);

        #20 amo_req(bus, `TL_ARITH_DATA, `TL_PARAM_ADD, 64'b1, 64'h400, 8);
        #20 read_req(bus, 64'h400, 8);
    end

    always @(posedge bus.d_valid) begin
        bus.a_valid <= `DISABLE;
        ack(bus);
    end

    /* Functions */
    function write_req(
        virtual tilelink.master bus,
        input [63:0] data,
        input [63:0] addr,
        input [3:0] size
    );

        $display($time,, "[%3x] Write req %x (%1d)...", addr, data, size);

        bus.a_opcode = `TL_PUT_F;
        bus.a_size = $clog2(size);
        bus.a_source = 4'b0000;
        bus.a_address = addr;
        bus.a_mask = 8'hFF;
        bus.a_data = data;
        bus.a_valid = `ENABLE;

    endfunction

    function read_req(
        virtual tilelink.master bus,
        input [63:0] addr,
        input [3:0] size
    );

        bus.a_opcode = `TL_GET;
        bus.a_size = $clog2(size);
        bus.a_source = 4'b0000;
        bus.a_address = addr;
        bus.a_mask = 8'hFF;
        bus.a_valid = `ENABLE;

    endfunction

    function amo_req(
        virtual tilelink.master bus,
        input [2:0]     opcode,
        input [2:0]     optype,
        input [63:0]    data,
        input [63:0]    addr,
        input [3:0]     size
    );

        $display($time,, "[%3x] AMO req %x (%1d)...", addr, data, size);

        bus.a_opcode = opcode;
        bus.a_param = optype;
        bus.a_size = $clog2(size);
        bus.a_source = 4'b0000;
        bus.a_address = addr;
        bus.a_mask = 8'hFF;
        bus.a_data = data;
        bus.a_valid = `ENABLE;

    endfunction

    function ack(virtual tilelink.master bus);
        if (bus.d_opcode == `TL_ACCESS_ACK_DATA)
            $display($time, "[%3x] Read (%1d) %x.",
                     bus.a_address, 1 << bus.d_size, bus.d_data);
        else
            $display($time,, "[%3x] Write Ack!", bus.a_address);
    endfunction

    initial begin
        #10240 $finish();
    end

endmodule
