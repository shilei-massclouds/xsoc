`timescale 1ns / 1ps

`include "isa.vh"
`include "virtio.vh"

module mmio_blk (
    input wire clk,
    input wire rst_n,
    tilelink.slave bus
);

    localparam S_IDLE = 1'b0;
    localparam S_BUSY = 1'b1;

    /* Controller */
    logic state, next_state;
    dff dff_state (clk, rst_n, `DISABLE, `DISABLE, next_state, state);

    /* Datapath */
    assign bus.a_ready = (state == S_IDLE);
    assign bus.d_valid = (state == S_BUSY);
    assign bus.d_denied = `DISABLE;
    /* The d_param indicates whether cached. */
    /* Uart has no cache. */
    assign bus.d_param = 2'b01;

    /* State transition */
    always @(state, bus.a_valid) begin
        case (state)
            S_IDLE:
                next_state = bus.a_valid ? S_BUSY : S_IDLE;
            S_BUSY:
                next_state = S_IDLE;
            default:
                next_state = S_IDLE;
        endcase
    end

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
        end else begin
            if ((state == S_IDLE) & bus.a_valid) begin
                if (bus.a_opcode == `TL_PUT_F) begin
                    $display($time,, "MMIO_BLK: write [%0x] %0x",
                             bus.a_address, bus.a_data);
                    if (bus.a_address == 'hffff) begin
                        ;
                    end
                    bus.d_opcode <= `TL_ACCESS_ACK;
                end else if (bus.a_opcode == `TL_GET) begin
                    $display($time,, "MMIO_BLK: read %0x", bus.a_address);
                    case (bus.a_address)
                        `VIRTIO_MMIO_MAGIC_VALUE:
                            bus.d_data <= {32'b0, "t", "r", "i", "v"};
                        `VIRTIO_MMIO_VERSION:
                            bus.d_data <= 64'h1;
                        `VIRTIO_MMIO_DEVICE_ID:
                            bus.d_data <= `VIRTIO_ID_BLOCK;
                        `VIRTIO_MMIO_VENDOR_ID:
                            bus.d_data <= {32'b0, "U", "M", "E", "Q"};
                        `VIRTIO_MMIO_DEVICE_FEATURES:
                            bus.d_data <= 64'h31006ed4;
                        default:
                            bus.d_data <= 64'b0;
                    endcase
                    bus.d_opcode <= `TL_ACCESS_ACK_DATA;
                end
                bus.d_size <= bus.a_size;
                bus.d_source <= bus.a_source;
            end
        end
    end

    dbg_mmio_blk dbg_mmio_blk (
        .clk    (clk    ),
        .rst_n  (rst_n  ),
        .bus    (bus    )
    );

endmodule
