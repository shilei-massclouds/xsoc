module zero_page (
    tilelink.slave bus
);

    assign bus.a_ready = `ENABLE;
    assign bus.d_valid = `ENABLE;
    assign bus.d_data = 64'b0;
    assign bus.d_denied = `DISABLE;
    assign bus.d_size = bus.a_size;
    assign bus.d_source = bus.a_source;
    assign bus.d_opcode = `TL_ACCESS_ACK_DATA;

endmodule
