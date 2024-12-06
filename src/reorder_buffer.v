// instructions are stored in the reorder buffer until they are committed to the register file
// commit instructions in order
module ReorderBuffer(
    input clk_in,
    input rst_in,
    input rdy_in,
// instruction from decoder
    output dec_en,
    output dec_empty_id,
    input dec_rdy,
    input [1:0] dec_type,
    input [31:0] dec_inst_res,
    input [`REG_WIDTH-1:0] dec_inst_dest,
    input [31:0] dec_inst_addr,
    input dec_predict,
// flush when prediction is wrong
    output flush,
// correct address to decoder
    output[31:0] predict_correct_pc,
// commit to register file
    output[`REG_WIDTH-1:0] commit_reg_id,
    output[31:0] commit_data,
    output[`ROB_WIDTH-1:0] commit_rob_id,
// register data to register file
    input[`ROB_WIDTH-1:0] reg_rob_id_j,
    output reg_ready_j,
    output[31:0] reg_data_j,
    input[`ROB_WIDTH-1:0] reg_rob_id_k,
    output reg_ready_k,
    output[31:0] reg_data_k,
// data from load store buffer
    output lsb_en,
    input lsb_rdy,
    input [`ROB_WIDTH-1:0] lsb_rob_id,
    input [31:0] lsb_data,
// data from reservation station
    output rs_en,
    input rs_rdy,
    input [`ROB_WIDTH-1:0] rs_rob_id,
    input [31:0] rs_data,
// commit info to load store buffer (to ensure store instructions are committed in order)
    input commit_empty,
    input[`ROB_WIDTH-1:0] commit_rob_id,
);
    reg[`ROB_WIDTH-1:0] head, tail;
    reg present[0:`ROB_SIZE-1];
    reg ready[0:`ROB_SIZE-1];
    reg [1:0] type[0:`ROB_SIZE-1];
    reg [31:0] inst_res[0:`ROB_SIZE-1];
    reg [`REG_WIDTH-1:0] inst_dest[0:`ROB_SIZE-1];
    reg [31:0] inst_addr[0:`ROB_SIZE-1];
    reg predict[0:`ROB_SIZE-1];
endmodule