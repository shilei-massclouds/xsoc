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

    bit [31:0]  guest_page_shift;
    bit [7:0]   status;
    bit         host_features_sel;
    bit         guest_features_sel;
    bit [63:0]  host_features = 64'h31006ed4;
    bit [63:0]  guest_features;
    bit [7:0]   config[256];
    bit [7:0]   queue_sel;
    bit [63:0]  vring_desc;
    bit [31:0]  vring_num;
    bit [31:0]  vring_align;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            config['h01] <= 'h08;
            config['h0c] <= 'hFE;
            config['h15] <= 'h02;
            config['h20] <= 'h01;
            config['h24] <= 'hFF;
            config['h25] <= 'hFF;
            config['h26] <= 'h3F;
            config['h28] <= 'h01;
            config['h2c] <= 'h01;
            config['h30] <= 'hFF;
            config['h31] <= 'hFF;
            config['h32] <= 'h3F;
        end else begin
            if ((state == S_IDLE) & bus.a_valid) begin
                if (bus.a_opcode == `TL_PUT_F) begin
                    $display($time,, "MMIO_BLK: write [%0x] (%0x)",
                             bus.a_address, bus.a_data);
                    case (bus.a_address)
                        `VIRTIO_MMIO_GUEST_PAGE_SIZE:
                            guest_page_shift <= $clog2(bus.a_data);
                        `VIRTIO_MMIO_STATUS:
                            status <= (bus.a_data & 'hff);
                        `VIRTIO_MMIO_DEVICE_FEATURES_SEL:
                            host_features_sel <= (bus.a_data != 0);
                        `VIRTIO_MMIO_DRIVER_FEATURES_SEL:
                            guest_features_sel <= (bus.a_data != 0);
                        `VIRTIO_MMIO_DRIVER_FEATURES:
                            if (~guest_features_sel)
                                guest_features <= bus.a_data & host_features;
                        `VIRTIO_MMIO_QUEUE_SEL:
                            if (bus.a_data < `VIRTIO_QUEUE_MAX)
                                queue_sel <= bus.a_data;
                        `VIRTIO_MMIO_QUEUE_NUM:
                            vring_num <= bus.a_data;
                        `VIRTIO_MMIO_QUEUE_ALIGN:
                            vring_align <= bus.a_data;
                        `VIRTIO_MMIO_QUEUE_PFN:
                            if (bus.a_data == 0) begin
                                /* RESET all fields */
                            end else begin
                                vring_desc <= (bus.a_data << guest_page_shift);
                                /* Set avail and used */
                            end
                        default:
                            ;
                    endcase
                    bus.d_opcode <= `TL_ACCESS_ACK;
                end else if (bus.a_opcode == `TL_GET) begin
                    $display($time,, "MMIO_BLK: read %0x", bus.a_address);
                    if (bus.a_address >= `VIRTIO_MMIO_CONFIG) begin
                        bus.d_data <= config[bus.a_address - `VIRTIO_MMIO_CONFIG];
                    end else begin
                        case (bus.a_address)
                            `VIRTIO_MMIO_MAGIC_VALUE:
                                bus.d_data <= {32'b0, "t", "r", "i", "v"};
                            `VIRTIO_MMIO_VERSION:
                                bus.d_data <= `VIRT_VERSION_LEGACY;
                            `VIRTIO_MMIO_DEVICE_ID:
                                bus.d_data <= `VIRTIO_ID_BLOCK;
                            `VIRTIO_MMIO_VENDOR_ID:
                                bus.d_data <= {32'b0, "U", "M", "E", "Q"};
                            `VIRTIO_MMIO_DEVICE_FEATURES:
                                bus.d_data <= host_features_sel ? 64'h0 :
                                                                host_features;
                            `VIRTIO_MMIO_STATUS:
                                bus.d_data <= status;
                            `VIRTIO_MMIO_QUEUE_PFN:
                                bus.d_data <= (vring_desc >> guest_page_shift);
                            `VIRTIO_MMIO_QUEUE_NUM_MAX:
                                bus.d_data <= `VIRTQUEUE_MAX_SIZE;
                            default:
                                bus.d_data <= 64'b0;
                        endcase
                    end
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
