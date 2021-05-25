interface tilelink;

    /* A Channel: Address */
    logic [2:0]     a_opcode;
    logic [2:0]     a_param;
    logic [2:0]     a_size;
    logic [3:0]     a_source;
    logic [63:0]    a_address;
    logic [7:0]     a_mask;
    logic [63:0]    a_data;
    logic           a_corrupt;
    logic           a_valid;
    logic           a_ready;

    /* D Channel: Ack & Data */
    logic [2:0]     d_opcode;
    logic [1:0]     d_param;
    logic [2:0]     d_size;
    logic [3:0]     d_source;
    logic [5:0]     d_sink;
    logic           d_denied;
    logic [63:0]    d_data;
    logic           d_corrupt;
    logic           d_valid;
    logic           d_ready;

    modport master(output a_opcode, a_param, a_size, a_source, a_address,
                   a_mask, a_data, a_corrupt, a_valid, input a_ready,
                   input d_opcode, d_param, d_size, d_source, d_sink,
                   d_denied, d_data, d_corrupt, d_valid, output d_ready);

    modport slave(input a_opcode, a_param, a_size, a_source, a_address,
                  a_mask, a_data, a_corrupt, a_valid, output a_ready,
                  output d_opcode, d_param, d_size, d_source, d_sink,
                  d_denied, d_data, d_corrupt, d_valid, input d_ready);

endinterface
