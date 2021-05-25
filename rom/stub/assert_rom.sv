module assert_rom (
    input wire      clk,
    input wire      rst_n,

    tilelink.master bus
);

    reg [63:0] inst[8] = '{
        'h000015b7f1402573,
        'hb303638d1005859b,
        'h029b00638e33ff83,
        'h931601f292930010,
        'h000e338313611e61,
        'hfe62cae300733023,
        'h0000000000008282,
        'h0000000000000000
    };

    reg [7:0] index;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            index <= 8'b0;
        end else begin
            if (bus.d_valid)
                index <= index + 1;
        end
    end

    property p0;
        @(posedge clk)
            disable iff (~rst_n)
            bus.d_valid |-> (bus.d_data == inst[index]);
    endproperty

    a0 : assert property (p0);

    initial begin
        #31000 $finish();
    end

endmodule