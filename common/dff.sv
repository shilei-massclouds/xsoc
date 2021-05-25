module dff #(
    parameter WIDTH = 1,
    parameter INIT_VAL = 1'b0
)(
    input   wire clk,
    input   wire rst_n,

    input   wire clear,
    input   wire stall,
    input   wire [WIDTH-1:0] d,
    output  wire [WIDTH-1:0] q
);

    reg [WIDTH-1:0] buffer;

    assign q = buffer;

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n || clear)
            buffer <= INIT_VAL;
        else if (stall)
            buffer <= buffer;
        else
            buffer <= d;
    end

endmodule