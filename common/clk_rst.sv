module clk_rst (
    output reg clk,
    output reg rst_n
);

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;

        #12 rst_n = 1'b1;
    end

    always #10 clk = ~clk;

endmodule
