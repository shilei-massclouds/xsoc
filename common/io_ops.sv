interface io_ops;

    logic       load_op;
    logic       store_op;
    logic       amo_add_op;
    logic       amo_swap_op;
    logic       lr_op;
    logic       sc_op;
    logic       amo_xor_op;
    logic       amo_or_op;
    logic       amo_and_op;
    logic       amo_min_op;
    logic       amo_max_op;
    logic       amo_minu_op;
    logic       amo_maxu_op;

    logic [2:0] size;
    logic [7:0] mask;

    modport src(output load_op, store_op, amo_add_op, amo_swap_op,
                lr_op, sc_op, amo_xor_op, amo_or_op, amo_and_op,
                amo_min_op, amo_max_op, amo_minu_op, amo_maxu_op,
                size, mask);
    modport dst(input load_op, store_op, amo_add_op, amo_swap_op,
                lr_op, sc_op, amo_xor_op, amo_or_op, amo_and_op,
                amo_min_op, amo_max_op, amo_minu_op, amo_maxu_op,
                size, mask);

endinterface
