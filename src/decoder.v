// extract instrction from memory, decode instruction, read data from reg, and store the decoded instruction in rob and (rs or lsb)
// manage jump and branch instructions, perform branch prediction and store PC
module Decoder(
    input clk_in,
    input rst_in,
    input rdy_in,
    input flush,
// raw instruction data from memory control
    output mc_en,
    output [31:0] mc_addr,
    input mc_rdy,
    input [31:0] mc_data,
// instruction to reorder buffer
    input rob_en,
    input rob_empty_id, // use rob index to look up
    output rob_rdy,
    output [1:0] rob_type,
    output [31:0] rob_inst_res,
    output [`REG_WIDTH-1:0] rob_inst_dest,
    output [31:0] rob_inst_addr,
    output rob_predict,
// correct address from reorder buffer
    input [31:0] predict_correct_pc,
// instruction to reservation station
    input rs_en,
    output rs_rdy,
    output [4:0] rs_type,
    output [31:0] rs_data_j,
    output [31:0] rs_data_k,
    output rs_pending_j,
    output rs_pending_k,
    output [`ROB_WIDTH-1:0] rs_dependency_j,
    output [`ROB_WIDTH-1:0] rs_dependency_k,
    output [`ROB_WIDTH-1:0] rs_rob_id,
    output [31:0] rs_imm,
// instruction to load store buffer
    input lsb_en,
    output lsb_rdy,
    output [3:0] lsb_type,
    output [31:0] lsb_data_j,
    output [31:0] lsb_data_k,
    output lsb_pending_j,
    output lsb_pending_k,
    output [`ROB_WIDTH-1:0] lsb_dependency_j,
    output [`ROB_WIDTH-1:0] lsb_dependency_k,
    output [`ROB_WIDTH-1:0] lsb_rob_id,
    output [31:0] lsb_imm,
// register data from register file
    output [`REG_WIDTH-1:0] reg_reg_id_j,
    output [`REG_WIDTH-1:0] reg_reg_id_k,
    input [31:0] reg_data_j,
    input [31:0] reg_data_k,
    input reg_pending_j,
    input reg_pending_k,
    input [`ROB_WIDTH-1:0] reg_dependency_j,
    input [`ROB_WIDTH-1:0] reg_dependency_k,
);
    reg busy;
    reg [31:0] pc;
    reg [31:0] inst;
endmodule