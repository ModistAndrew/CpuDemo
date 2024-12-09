// store and execute instructions
// find the nearest executable instruction and execute it
module ReservationStation(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input flush,
// instruction from decoder
    output dec_full,
    input dec_rdy,
    input [`RS_TYPE_WIDTH-1:0] dec_type,
    input [31:0] dec_data_j,
    input [31:0] dec_data_k,
    input dec_pending_j,
    input dec_pending_k,
    input [`ROB_WIDTH-1:0] dec_dependency_j,
    input [`ROB_WIDTH-1:0] dec_dependency_k,
    input [`ROB_WIDTH-1:0] dec_rob_id,
    input [31:0] dec_imm,
// data to reorder buffer
    input rob_en,
    output rob_rdy,
    output [`ROB_WIDTH-1:0] rob_rob_id,
    output [31:0] rob_data,
// data from alu
    output alu_en,
    output [31:0] alu_rob_id_in,
    output [31:0] alu_data_j,
    output [31:0] alu_data_k,
    output [31:0] alu_imm,
    output [`RS_TYPE_WIDTH-1:0] alu_type,
    input alu_rdy,
    input [31:0] alu_rob_id_out,
    input [31:0] alu_result,
// broadcast from rs
    input rs_broadcast_en,
    input [31:0] rs_broadcast_rob_id,
    input [31:0] rs_broadcast_data,
// broadcast from lsb
    input lsb_broadcast_en,
    input [31:0] lsb_broadcast_rob_id,
    input [31:0] lsb_broadcast_data,
// broadcast to rs and lsb
    output broadcast_en,
    output [31:0] broadcast_rob_id,
    output [31:0] broadcast_data
);
// variables
    reg present[0:`RS_SIZE-1];
    reg [`RS_TYPE_WIDTH-1:0] type[0:`RS_SIZE-1];
    reg [31:0] data_j[0:`RS_SIZE-1];
    reg [31:0] data_k[0:`RS_SIZE-1];
    reg pending_j[0:`RS_SIZE-1];
    reg pending_k[0:`RS_SIZE-1];
    reg [`ROB_WIDTH-1:0] dependency_j[0:`RS_SIZE-1];
    reg [`ROB_WIDTH-1:0] dependency_k[0:`RS_SIZE-1];
    reg [`ROB_WIDTH-1:0] rob_id[0:`RS_SIZE-1];
    reg [31:0] imm[0:`RS_SIZE-1];
// wires
    // matrix to find executable and empty instruction in combinational logic
    wire empty_tree[1:2*`RS_SIZE-1];
    wire executable_tree[1:2*`RS_SIZE-1];
    wire [`RS_WIDTH-1:0] empty_pos_tree[1:2*`RS_SIZE-1];
    wire [`RS_WIDTH-1:0] executable_pos_tree[1:2*`RS_SIZE-1];
    generate
        genvar i;
        for (i = 0; i < `RS_SIZE; i = i + 1) begin
            assign empty_tree[i+`RS_SIZE] = !present[i];
            assign executable_tree[i+`RS_SIZE] = present[i] && !pending_j[i] && !pending_k[i];
            assign empty_pos_tree[i+`RS_SIZE] = i;
            assign executable_pos_tree[i+`RS_SIZE] = i;
            if (i != 0) begin
                assign empty_tree[i] = empty_tree[2*i] || empty_tree[2*i+1];
                assign executable_tree[i] = executable_tree[2*i] || executable_tree[2*i+1];
                assign empty_pos_tree[i] = empty_tree[2*i] ? empty_pos_tree[2*i] : empty_pos_tree[2*i+1];
                assign executable_pos_tree[i] = executable_tree[2*i] ? executable_pos_tree[2*i] : executable_pos_tree[2*i+1];
            end
        end
    endgenerate
    wire empty = empty_tree[1];
    wire executable = executable_tree[1];
    wire [`RS_WIDTH-1:0] empty_pos = empty_pos_tree[1];
    wire [`RS_WIDTH-1:0] executable_pos = executable_pos_tree[1];
    // combine input
    wire rs_broadcast_meet_insert_j = rs_broadcast_en && rs_broadcast_rob_id == dec_dependency_j;
    wire lsb_broadcast_meet_insert_j = lsb_broadcast_en && lsb_broadcast_rob_id == dec_dependency_j;
    wire rs_broadcast_meet_insert_k = rs_broadcast_en && rs_broadcast_rob_id == dec_dependency_k;
    wire lsb_broadcast_meet_insert_k = lsb_broadcast_en && lsb_broadcast_rob_id == dec_dependency_k;
// output
    assign dec_full = !empty;
    assign rob_rdy = alu_rdy;
    assign rob_rob_id = alu_rob_id_out;
    assign rob_data = alu_result;
    assign alu_en = executable;
    assign alu_rob_id_in = rob_id[executable_pos];
    assign alu_data_j = data_j[executable_pos];
    assign alu_data_k = data_k[executable_pos];
    assign alu_imm = imm[executable_pos];
    assign alu_type = type[executable_pos];
    assign broadcast_en = alu_rdy;
    assign broadcast_rob_id = alu_rob_id_out;
    assign broadcast_data = alu_result;
// cycle
    always @(posedge clk_in) begin: Main
        integer i;
        if (rst_in) begin
            for (i = 0; i < `RS_SIZE; i = i + 1) begin
                present[i] <= 0;
                type[i] <= 0;
                data_j[i] <= 0;
                data_k[i] <= 0;
                pending_j[i] <= 0;
                pending_k[i] <= 0;
                dependency_j[i] <= 0;
                dependency_k[i] <= 0;
                rob_id[i] <= 0;
                imm[i] <= 0;
            end
        end else if (!rdy_in) begin  // skip
        end else if (flush) begin  // flush
        // TODO
        end else begin
            // insert
            if (dec_rdy) begin
                present[empty_pos] <= 1;
                type[empty_pos] <= dec_type;
                data_j[empty_pos] <= !dec_pending_j ? dec_data_j : rs_broadcast_meet_insert_j ? rs_broadcast_data : lsb_broadcast_meet_insert_j ? lsb_broadcast_data : 0;
                data_k[empty_pos] <= !dec_pending_k ? dec_data_k : rs_broadcast_meet_insert_k ? rs_broadcast_data : lsb_broadcast_meet_insert_k ? lsb_broadcast_data : 0;
                pending_j[empty_pos] <= dec_pending_j && !rs_broadcast_meet_insert_j && !lsb_broadcast_meet_insert_j;
                pending_k[empty_pos] <= dec_pending_k && !rs_broadcast_meet_insert_k && !lsb_broadcast_meet_insert_k;
                dependency_j[empty_pos] <= dec_dependency_j;
                dependency_k[empty_pos] <= dec_dependency_k;
                rob_id[empty_pos] <= dec_rob_id;
                imm[empty_pos] <= dec_imm;
            end
            // update
            for (i = 0; i < `RS_SIZE; i = i + 1) begin
                if (pending_j[i]) begin
                    if (rs_broadcast_en && rs_broadcast_rob_id == dependency_j[i]) begin
                        data_j[i] <= rs_broadcast_data;
                        pending_j[i] <= 0;
                    end else if (lsb_broadcast_en && lsb_broadcast_rob_id == dependency_j[i]) begin
                        data_j[i] <= lsb_broadcast_data;
                        pending_j[i] <= 0;
                    end
                end
                if (pending_k[i]) begin
                    if (rs_broadcast_en && rs_broadcast_rob_id == dependency_k[i]) begin
                        data_k[i] <= rs_broadcast_data;
                        pending_k[i] <= 0;
                    end else if (lsb_broadcast_en && lsb_broadcast_rob_id == dependency_k[i]) begin
                        data_k[i] <= lsb_broadcast_data;
                        pending_k[i] <= 0;
                    end
                end
            end
            if (executable) begin
                present[executable_pos] <= 0;
            end
        end
    end
endmodule