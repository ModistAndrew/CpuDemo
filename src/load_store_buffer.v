`include "params.v"
// store and execute load and store instructions
// check the head: if load, execute; if store, wait for commit
module LoadStoreBuffer(
    input clk_in,
    input rst_in,
    input rdy_in,
    input flush,
// memory data from/to memory control
    output mc_en,
    output [31:0] mc_addr,
    output [`LSB_TYPE_WIDTH-1:0] mc_type,
    output [31:0] mc_write_data,
    input mc_rdy,
    input [31:0] mc_read_data,
// instruction from decoder
    output dec_full,
    input dec_rdy,
    input [`LSB_TYPE_WIDTH-1:0] dec_type,
    input [31:0] dec_data_j,
    input [31:0] dec_data_k,
    input dec_pending_j,
    input dec_pending_k,
    input [`ROB_WIDTH-1:0] dec_dependency_j,
    input [`ROB_WIDTH-1:0] dec_dependency_k,
    input [`ROB_WIDTH-1:0] dec_rob_id,
    input [31:0] dec_imm,
// data to reorder buffer
    output rob_rdy,
    output [`ROB_WIDTH-1:0] rob_rob_id,
    output [31:0] rob_data,
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
    output [31:0] broadcast_data,
// commit info from reorder buffer (to ensure store instructions are executed in order)
    input commit_info_empty,
    input [`ROB_WIDTH-1:0] commit_info_current_rob_id
);
    reg[`LSB_WIDTH-1:0] head;
    reg[`LSB_WIDTH-1:0] tail;
    reg present[0:`LSB_SIZE-1];
    reg [`LSB_TYPE_WIDTH-1:0] type[0:`LSB_SIZE-1];
    reg [31:0] data_j[0:`LSB_SIZE-1];
    reg [31:0] data_k[0:`LSB_SIZE-1];
    reg pending_j[0:`LSB_SIZE-1];
    reg pending_k[0:`LSB_SIZE-1];
    reg [`ROB_WIDTH-1:0] dependency_j[0:`LSB_SIZE-1];
    reg [`ROB_WIDTH-1:0] dependency_k[0:`LSB_SIZE-1];
    reg [`ROB_WIDTH-1:0] rob_id[0:`LSB_SIZE-1];
    reg [31:0] imm[0:`LSB_SIZE-1];
// wires
    wire rs_broadcast_meet_insert_j = rs_broadcast_en && rs_broadcast_rob_id == dec_dependency_j;
    wire lsb_broadcast_meet_insert_j = lsb_broadcast_en && lsb_broadcast_rob_id == dec_dependency_j;
    wire rs_broadcast_meet_insert_k = rs_broadcast_en && rs_broadcast_rob_id == dec_dependency_k;
    wire lsb_broadcast_meet_insert_k = lsb_broadcast_en && lsb_broadcast_rob_id == dec_dependency_k;

    wire head_type = type[head];
    wire head_rob_id = rob_id[head];
// output
    assign mc_en = present[head] && !pending_j[head] && !pending_k[head] && 
    (head_type[3] || !commit_info_empty && commit_info_current_rob_id == head); // if store, wait for commit
    assign mc_addr = data_j[head] + imm[head];
    assign mc_type = head_type;
    assign mc_write_data = data_k[head];
    assign dec_full = head == tail && present[head];
    assign rob_rdy = mc_rdy;
    assign rob_rob_id = head_rob_id;
    assign rob_data = mc_read_data;
    assign broadcast_en = mc_rdy;
    assign broadcast_rob_id = head_rob_id;
    assign broadcast_data = mc_read_data;
// cycle
    always @(posedge clk_in) begin: Main
        integer i;
        if (rst_in || flush && rdy_in) begin
            head <= 0;
            tail <= 0;
            for (i = 0; i < `LSB_SIZE; i = i + 1) begin
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
        end else if (rdy_in) begin
            // insert
            if (dec_rdy) begin
                present[tail] <= 1;
                type[tail] <= dec_type;
                data_j[tail] <= !dec_pending_j ? dec_data_j : rs_broadcast_meet_insert_j ? rs_broadcast_data : lsb_broadcast_data;
                data_k[tail] <= !dec_pending_k ? dec_data_k : rs_broadcast_meet_insert_k ? rs_broadcast_data : lsb_broadcast_data;
                pending_j[tail] <= dec_pending_j && !rs_broadcast_meet_insert_j && !lsb_broadcast_meet_insert_j;
                pending_k[tail] <= dec_pending_k && !rs_broadcast_meet_insert_k && !lsb_broadcast_meet_insert_k;
                dependency_j[tail] <= dec_dependency_j;
                dependency_k[tail] <= dec_dependency_k;
                rob_id[tail] <= dec_rob_id;
                imm[tail] <= dec_imm;
            end
            // update
            for (i = 0; i < `LSB_SIZE; i = i + 1) begin
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
            if (mc_rdy) begin
                head <= head + 1;
                present[head] <= 0;
            end
        end
    end
endmodule