`include "params.v"
// instructions are stored in the reorder buffer until they are committed to the register file
// commit instructions in order
module ReorderBuffer(
    input clk_in,
    input rst_in,
    input rdy_in,
    input flush,
// instruction from decoder
    output dec_full,
    output [`ROB_WIDTH-1:0] dec_empty_id,
    input dec_rdy,
    input dec_committable,
    input [31:0] dec_res,
    input [`ROB_TYPE_WIDTH-1:0] dec_type,
    input [`REG_WIDTH-1:0] dec_dest,
    input [31:0] dec_next_addr,
    input [31:0] dec_jump_addr,
    input dec_predict,
// flush when prediction is wrong
    output reg flush_out,
// correct address to decoder
    output reg [31:0] predict_correct_pc,
// commit to register file
    output [`REG_WIDTH-1:0] commit_reg_id,
    output [31:0] commit_data,
    output [`ROB_WIDTH-1:0] commit_rob_id,
// register data to register file
    input [`ROB_WIDTH-1:0] reg_rob_id_j,
    input [`ROB_WIDTH-1:0] reg_rob_id_k,
    output reg_ready_j,
    output reg_ready_k,
    output [31:0] reg_data_j,
    output [31:0] reg_data_k,
// data from load store buffer
    input lsb_rdy,
    input [`ROB_WIDTH-1:0] lsb_rob_id,
    input [31:0] lsb_data,
// data from reservation station
    input rs_rdy,
    input [`ROB_WIDTH-1:0] rs_rob_id,
    input [31:0] rs_data,
    input rs_set_jump_addr,
// commit info to load store buffer (to ensure store instructions are committed in order)
    output commit_info_empty,
    output [`ROB_WIDTH-1:0] commit_info_current_rob_id
);
    reg [`ROB_WIDTH-1:0] head;
    reg [`ROB_WIDTH-1:0] tail;
    reg present[0:`ROB_SIZE-1];
    reg committable[0:`ROB_SIZE-1];
    reg [31:0] res[0:`ROB_SIZE-1];
    reg [`ROB_TYPE_WIDTH-1:0] type[0:`ROB_SIZE-1];
    reg [`REG_WIDTH-1:0] dest[0:`ROB_SIZE-1];
    reg [31:0] next_addr[0:`ROB_SIZE-1];
    reg [31:0] jump_addr[0:`ROB_SIZE-1];
    reg predict[0:`ROB_SIZE-1];

// wires
    wire commit_en = present[head] && committable[head] && type[head][0]; // only REG or JALR needs to commit to register file
    wire [31:0] commit_res = res[head];
    wire [`ROB_TYPE_WIDTH-1:0] commit_type = type[head];
    wire commit_next_addr = next_addr[head];
    wire commit_jump_addr = jump_addr[head];
    wire commit_predict = predict[head];

    wire search_committable_j = committable[reg_rob_id_j];
    wire search_committable_k = committable[reg_rob_id_k];
    wire rs_meet_j = rs_rdy && rs_rob_id == reg_rob_id_j;
    wire rs_meet_k = rs_rdy && rs_rob_id == reg_rob_id_k;
    wire lsb_meet_j = lsb_rdy && lsb_rob_id == reg_rob_id_j;
    wire lsb_meet_k = lsb_rdy && lsb_rob_id == reg_rob_id_k;
    wire dec_meet_j = dec_rdy && dec_committable && tail == reg_rob_id_j;
    wire dec_meet_k = dec_rdy && dec_committable && tail == reg_rob_id_k;
// output
    assign dec_full = head == tail && present[head];
    assign dec_empty_id = tail;
    assign reg_ready_j = search_committable_j || rs_meet_j || lsb_meet_j || dec_meet_j;
    assign reg_ready_k = search_committable_k || rs_meet_k || lsb_meet_k || dec_meet_k;
    assign reg_data_j = dec_meet_j ? dec_res : lsb_meet_j ? lsb_data : rs_meet_j ? rs_data : res[reg_rob_id_j];
    assign reg_data_k = dec_meet_k ? dec_res : lsb_meet_k ? lsb_data : rs_meet_k ? rs_data : res[reg_rob_id_k];
    assign commit_reg_id = commit_en ? dest[head] : 0;
    assign commit_data = res[head];
    assign commit_rob_id = head; // use combinational logic here as JALR must be committed immediately (flush will be issued in the next cycle)
    assign commit_info_empty = !present[head];
    assign commit_info_current_rob_id = head;
// cycle
    always @(posedge clk_in) begin: Main
        integer i;
        if (rst_in || flush && rdy_in) begin
            head <= 0;
            tail <= 0;
            flush_out <= 0;
            predict_correct_pc <= 0;
            for (i = 0; i < `ROB_SIZE; i = i + 1) begin
                present[i] <= 0;
                committable[i] <= 0;
                res[i] <= 0;
                type[i] <= 0;
                dest[i] <= 0;
                next_addr[i] <= 0;
                jump_addr[i] <= 0;
                predict[i] <= 0;
            end
        end else if (rdy_in) begin
            // insert
            if (dec_rdy) begin
                tail <= tail + 1;
                present[tail] <= 1;
                committable[tail] <= dec_committable;
                res[tail] <= dec_res;
                type[tail] <= dec_type;
                dest[tail] <= dec_dest;
                next_addr[tail] <= dec_next_addr;
                jump_addr[tail] <= dec_jump_addr;
                predict[tail] <= dec_predict;
            end
            // update
            if (rs_rdy) begin
                committable[rs_rob_id] <= 1;
                if (rs_set_jump_addr) begin
                    jump_addr[rs_rob_id] <= rs_data;
                end else begin
                    res[rs_rob_id] <= rs_data;
                end
            end
            if (lsb_rdy) begin
                committable[lsb_rob_id] <= 1;
                res[lsb_rob_id] <= lsb_data;
            end
            // commit
            if (commit_en) begin
                head <= head + 1;
                present[head] <= 0;
                if (commit_type[1]) begin // BRANCH OR JALR (REG is done by wire)
                    if (commit_type[0]) begin // JALR
                        flush_out <= 1;
                        predict_correct_pc <= commit_jump_addr;
                    end else if (commit_predict ^ commit_res[0]) begin // BRANCH prediction is wrong
                        flush_out <= 1;
                        predict_correct_pc <= commit_res[0] ? commit_jump_addr : commit_next_addr;
                    end
                end
            end
        end
    end
endmodule