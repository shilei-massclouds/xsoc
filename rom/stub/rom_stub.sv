`timescale 1ns / 1ps

`include "isa.vh"

module rom (
    input wire clk,
    input wire rst_n,

    tilelink.slave bus
);
    localparam S_IDLE = 1'b0;
    localparam S_BUSY = 1'b1;

    /* Datapath: Internal data cells in ROM */
    reg [63:0] cells[bit[60:0]];

    /* Controller */
    logic state, next_state;
    dff dff_state(clk, rst_n, `DISABLE, `DISABLE, next_state, state);

    assign bus.a_ready = (state == S_IDLE);
    assign bus.d_param = 2'b0;

    /* State transition */
    always @(rst_n, state, bus.a_valid, bus.d_ready) begin
        case (state)
            S_IDLE:
                next_state = bus.a_valid ? S_BUSY : S_IDLE;
            S_BUSY:
                next_state = bus.d_ready ? S_IDLE : S_BUSY;
            default:
                next_state = S_IDLE;
        endcase
    end

    /* Output operations */
    reg op_data = `DISABLE;

    always @(rst_n, state, bus.a_valid, bus.d_ready) begin
        op_data = `DISABLE;
        case (state)
            S_IDLE:
                if (bus.a_valid) op_data = `ENABLE;
            S_BUSY:
                op_data = `DISABLE;
        endcase
    end

    /* Datapath */
    wire is_get = (bus.a_opcode == `TL_GET);

    wire [60:0] addr = bus.a_address[63:3];

    /* Todo: bus.a_corrupt means lr or sc */
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            bus.d_valid <= `DISABLE;
            bus.d_data <= 64'b0;
        end else begin
            bus.d_valid <= `DISABLE;
            bus.d_data <= 64'b0;
            bus.d_denied <= `DISABLE;

            if (op_data) begin
                bus.d_size <= bus.a_size;
                bus.d_source <= bus.a_source;
                if (is_get) begin
                    bus.d_data <= cells[addr];
                    bus.d_opcode <= `TL_ACCESS_ACK_DATA;
                end
                bus.d_valid <= `ENABLE;
                bus.d_denied <= `ENABLE;
            end
        end
    end

    dbg_rom u_dbg_rom (
        .clk   (clk         ),
        .rst_n (rst_n       ),
        .valid (bus.d_valid ),
        .data  (bus.d_data  )
    );

    /* Initialize rom with firmware */
    initial begin
        string test;
        string dev;
        longint handle;
        int size = 0;

        dev = getenv("START_DEV");
        test = getenv("TEST");
        if (test.len() > 0) begin
            $display("Test: %s", test);
            `LOAD_IMG({test, ".bin"}, 0, size)
        end else if (dev == "ram") begin
            `LOAD_IMG("data/simple_head.bin", 0, size)
            `LOAD_IMG("data/virt.dtb", 'h100, size)
            $display("###### Simple Head!!!");
        end else begin
            `LOAD_IMG("data/head.bin", 0, size)
            `LOAD_IMG("data/virt.dtb", 'h100, size)
            `LOAD_IMG("data/fw_jump.bin", 'h2000, size)
            cells['h3ff] = size;
            `LOAD_IMG("data/payload.bin", 'h20000, size)
            cells['h3fff] = size;
            $display("###### ROM!!! %x, %x, %x",
                     size, cells['h3ff], cells['h3fff]);
        end
    end

endmodule
