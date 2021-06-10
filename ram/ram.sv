`timescale 1ns / 1ps

`include "isa.vh"

module ram (
    input wire clk,
    input wire rst_n,
    tilelink.slave bus
);

    localparam S_IDLE = 1'b0;
    localparam S_BUSY = 1'b1;

    /* Datapath: Internal data cells in RAM */
    reg [63:0] cells[bit[60:0]];

    /* Controller */
    logic state, next_state;
    dff dff_state (clk, rst_n, `DISABLE, `DISABLE, next_state, state);

    /* State transition */
    always @(state, bus.a_valid, bus.d_ready) begin
        case (state)
            S_IDLE:
                next_state = bus.a_valid ? S_BUSY : S_IDLE;
            S_BUSY:
                next_state = S_IDLE;
            default:
                next_state = S_IDLE;
        endcase
    end

    /* Output operations */
    reg op_data = `DISABLE;

    always @(state, bus.a_valid, bus.d_ready) begin
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
    wire is_put_f = (bus.a_opcode == `TL_PUT_F);
    wire is_put_p = (bus.a_opcode == `TL_PUT_P);
    wire is_put = (is_put_f | is_put_p);
    wire is_arith = (bus.a_opcode == `TL_ARITH_DATA);
    wire is_logic = (bus.a_opcode == `TL_LOGIC_DATA);

    wire [7:0] size_mask = {{4{bus.a_size[1] & bus.a_size[0]}},
                            {2{bus.a_size[1]}},
                            {bus.a_size[1] | bus.a_size[0]}, 1'b1};
    wire [60:0] addr = bus.a_address[63:3];
    wire [2:0] offset = bus.a_address[2:0];
    wire [63:0] a_data = bus.a_data << (8 * offset);
    wire [7:0] a_mask = (bus.a_mask & size_mask) << offset;
    wire [63:0] mask = {{8{a_mask[7]}}, {8{a_mask[6]}},
                        {8{a_mask[5]}}, {8{a_mask[4]}},
                        {8{a_mask[3]}}, {8{a_mask[2]}},
                        {8{a_mask[1]}}, {8{a_mask[0]}}};

`define UPDATE_CELL(val) \
    ((cells[addr] & ~mask) | (((val) << (8 * offset)) & mask))

`define OLDVAL ((cells[addr] & mask) >> (8 * offset))
`define NEWVAL ((a_data & mask) >> (8 * offset))

    logic [63:0] mon_put_addr;

    /* Todo: bus.a_corrupt means lr or sc */
    assign bus.a_ready = `ENABLE;
    assign bus.d_param = 2'b0;
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
                if (is_put) begin
                    cells[addr] <= (cells[addr] & ~mask) | (a_data & mask);
                    bus.d_opcode <= `TL_ACCESS_ACK;
                    if (bus.a_corrupt)
                        bus.d_data <= 64'b0;
                    mon_put_addr <= bus.a_address;
                end else if (is_get) begin
                    bus.d_data <= cells[addr];
                    bus.d_opcode <= `TL_ACCESS_ACK_DATA;
                end else if (is_arith) begin
                    bus.d_opcode <= `TL_ACCESS_ACK_DATA;
                    bus.d_data <= cells[addr];
                    if (bus.a_param == `TL_PARAM_ADD) begin
                        cells[addr] <=
                            `UPDATE_CELL(`OLDVAL + `NEWVAL);
                        mon_put_addr <= bus.a_address;
                    end else if (bus.a_param == `TL_PARAM_MIN) begin
                        if (compare_lt(`NEWVAL, `OLDVAL, bus.a_size)) begin
                            cells[addr] <= `UPDATE_CELL(`NEWVAL);
                            mon_put_addr <= bus.a_address;
                        end
                    end else if (bus.a_param == `TL_PARAM_MAX) begin
                        if (compare_lt(`OLDVAL, `NEWVAL, bus.a_size)) begin
                            cells[addr] <= `UPDATE_CELL(`OLDVAL);
                            mon_put_addr <= bus.a_address;
                        end
                    end else if (bus.a_param == `TL_PARAM_MINU) begin
                        if (`OLDVAL > `NEWVAL) begin
                            cells[addr] <= `UPDATE_CELL(`NEWVAL);
                            mon_put_addr <= bus.a_address;
                        end
                    end else if (bus.a_param == `TL_PARAM_MAXU) begin
                        if (`OLDVAL < `NEWVAL) begin
                            cells[addr] <= `UPDATE_CELL(`OLDVAL);
                            mon_put_addr <= bus.a_address;
                        end
                    end
                end else if (is_logic) begin
                    bus.d_opcode <= `TL_ACCESS_ACK_DATA;
                    bus.d_data <= cells[addr];
                    if (bus.a_param == `TL_PARAM_SWAP) begin
                        cells[addr] <= `UPDATE_CELL(`NEWVAL);
                        mon_put_addr <= bus.a_address;
                    end if (bus.a_param == `TL_PARAM_XOR) begin
                        cells[addr] <= `UPDATE_CELL(`NEWVAL ^ `OLDVAL);
                        mon_put_addr <= bus.a_address;
                    end if (bus.a_param == `TL_PARAM_OR) begin
                        cells[addr] <= `UPDATE_CELL(`NEWVAL | `OLDVAL);
                        mon_put_addr <= bus.a_address;
                    end if (bus.a_param == `TL_PARAM_AND) begin
                        cells[addr] <= `UPDATE_CELL(`NEWVAL & `OLDVAL);
                        mon_put_addr <= bus.a_address;
                    end
                end
                bus.d_valid <= `ENABLE;
                bus.d_denied <= `ENABLE;
            end
        end
    end

    function logic compare_lt(logic [63:0] first,
                              logic [63:0] second,
                              logic [2:0] size);
        logic sign_ext = size[1] & ~size[0];
        logic [63:0] d1 = sign_ext ? {{32{first[31]}}, first[31:0]} : first;
        logic [63:0] d2 = sign_ext ? {{32{second[31]}}, second[31:0]} : second;

        return (d1[63] & ~d2[63]) |
               ((d1[63] & d2[63]) & (d1[62:0] > d2[62:0])) |
               ((~d1[63] & ~d2[63]) & (d1[62:0] < d2[62:0]));
    endfunction

    dbg_ram u_dbg_ram (
        .clk   (clk   ),
        .rst_n (rst_n ),
        .mask  (mask  ),
        .state (state ),
        .bus   (bus   )
    );

//`define MON_MEM
`ifdef MON_MEM
    /* Monitor store data */
    always @(mon_put_addr) begin
        if (mon_put_addr)
            $display($time,, "Mem[%x]: %x",
                     'h80000000 + mon_put_addr, cells[mon_put_addr[63:3]]);
    end
`endif

    /* Initialize ram with firmware */
    initial begin
        string dev;
        longint handle;
        int size = 0;

        dev = getenv("START_DEV");
        if (dev == "ram") begin
            `LOAD_IMG("data/fw_jump.bin", 'h0, size)
            `LOAD_IMG("data/payload.bin", 'h200000, size)
            $display("###### RAM!!! %x", size);
        end
    end

endmodule
