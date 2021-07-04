`timescale 1ns / 1ps

`include "isa.vh"

module ram (
    input wire clk,
    input wire rst_n,
    input wire [63:0] pc,
    tilelink.slave bus
);

    localparam S_IDLE = 1'b0;
    localparam S_BUSY = 1'b1;

    /* Controller */
    logic state, next_state;
    dff dff_state (clk, rst_n, `DISABLE, `DISABLE, next_state, state);

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

    /* Output operations */
    reg op_data = `DISABLE;

    always @(state, bus.a_valid) begin
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
    wire [63:0] addr = bus.a_address;
    wire [2:0] offset = bus.a_address[2:0];
    wire [63:0] a_data = bus.a_data << (8 * offset);
    wire [7:0] a_mask = (bus.a_mask & size_mask) << offset;
    wire [63:0] mask = {{8{a_mask[7]}}, {8{a_mask[6]}},
                        {8{a_mask[5]}}, {8{a_mask[4]}},
                        {8{a_mask[3]}}, {8{a_mask[2]}},
                        {8{a_mask[1]}}, {8{a_mask[0]}}};

`define UPDATE_CELL(val) \
    ((get_cell(addr) & ~mask) | (((val) << (8 * offset)) & mask))

`define OLDVAL ((get_cell(addr) & mask) >> (8 * offset))
`define NEWVAL ((a_data & mask) >> (8 * offset))

    /* Todo: bus.a_corrupt means lr or sc */
    assign bus.a_ready = `ENABLE;
    assign bus.d_param = 2'b0;
    assign bus.d_valid = (state == S_BUSY);
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            bus.d_data <= 64'b0;
        end else begin
            if (op_data) begin
                bus.d_size <= bus.a_size;
                bus.d_source <= bus.a_source;
                if (is_put) begin
                    if (addr == 'h7fff_f000)
                        $display($time,, "### pc(%x) bus.a_data(%x)", pc, bus.a_data);

                    set_cell(addr, (get_cell(addr) & ~mask) | (a_data & mask));
                    bus.d_opcode <= `TL_ACCESS_ACK;
                    if (bus.a_corrupt)
                        bus.d_data <= 64'b0;
                end else if (is_get) begin
                    bus.d_data <= get_cell(addr);
                    bus.d_opcode <= `TL_ACCESS_ACK_DATA;
                end else if (is_arith) begin
                    bus.d_opcode <= `TL_ACCESS_ACK_DATA;
                    if (bus.a_param == `TL_PARAM_ADD) begin
                        bus.d_data <= set_cell(addr, `UPDATE_CELL(`OLDVAL + `NEWVAL));
                    end else if (bus.a_param == `TL_PARAM_MIN) begin
                        if (compare_lt(`NEWVAL, `OLDVAL, bus.a_size)) begin
                            bus.d_data <= set_cell(addr, `UPDATE_CELL(`NEWVAL));
                        end else begin
                            bus.d_data <= get_cell(addr);
                        end
                    end else if (bus.a_param == `TL_PARAM_MAX) begin
                        if (compare_lt(`OLDVAL, `NEWVAL, bus.a_size)) begin
                            bus.d_data <= set_cell(addr, `UPDATE_CELL(`NEWVAL));
                        end else begin
                            bus.d_data <= get_cell(addr);
                        end
                    end else if (bus.a_param == `TL_PARAM_MINU) begin
                        if (`OLDVAL > `NEWVAL) begin
                            bus.d_data <= set_cell(addr, `UPDATE_CELL(`NEWVAL));
                        end else begin
                            bus.d_data <= get_cell(addr);
                        end
                    end else if (bus.a_param == `TL_PARAM_MAXU) begin
                        if (`OLDVAL < `NEWVAL) begin
                            bus.d_data <= set_cell(addr, `UPDATE_CELL(`NEWVAL));
                        end else begin
                            bus.d_data <= get_cell(addr);
                        end
                    end
                end else if (is_logic) begin
                    bus.d_opcode <= `TL_ACCESS_ACK_DATA;
                    if (bus.a_param == `TL_PARAM_SWAP) begin
                        bus.d_data <= set_cell(addr, `UPDATE_CELL(`NEWVAL));
                    end if (bus.a_param == `TL_PARAM_XOR) begin
                        bus.d_data <= set_cell(addr, `UPDATE_CELL(`NEWVAL ^ `OLDVAL));
                    end if (bus.a_param == `TL_PARAM_OR) begin
                        bus.d_data <= set_cell(addr, `UPDATE_CELL(`NEWVAL | `OLDVAL));
                    end if (bus.a_param == `TL_PARAM_AND) begin
                        bus.d_data <= set_cell(addr, `UPDATE_CELL(`NEWVAL & `OLDVAL));
                    end
                end
                bus.d_denied <= `ENABLE;
            end else begin
                bus.d_data <= 64'b0;
                bus.d_denied <= `DISABLE;
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
        .pc    (pc    ),
        .mask  (mask  ),
        .state (state ),
        .bus   (bus   )
    );

    initial begin
        if (getenv("RESTORE").len() > 0)
            restore_mem(32'hFFFF_FFFF);
        else
            init_cells(32'hFFFF_FFFF);
    end

endmodule
