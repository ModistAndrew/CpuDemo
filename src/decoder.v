`include "params.v"
// extract instrction from memory, decode instruction, read data from reg, and store the decoded instruction in rob and (rs or lsb)
// manage jump and branch instructions, perform branch prediction and store PC
module Decoder (
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
    input rob_full,
    input rob_empty_id,  // use rob index to look up
    output rob_rdy,
    output [`ROB_TYPE_WIDTH-1:0] rob_type,
    output [`REG_WIDTH-1:0] rob_dest,
    output [31:0] rob_inst_addr,
    output rob_predict,
    // correct address from reorder buffer
    input [31:0] predict_correct_pc,
    // instruction to reservation station
    input rs_full,
    output rs_rdy,
    output [`RS_TYPE_WIDTH-1:0] rs_type,
    output [31:0] rs_data_j,
    output [31:0] rs_data_k,
    output rs_pending_j,
    output rs_pending_k,
    output [`ROB_WIDTH-1:0] rs_dependency_j,
    output [`ROB_WIDTH-1:0] rs_dependency_k,
    output [`ROB_WIDTH-1:0] rs_rob_id,
    output [31:0] rs_imm,
    // instruction to load store buffer
    input lsb_full,
    output lsb_rdy,
    output [`LSB_TYPE_WIDTH-1:0] lsb_type,
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
    input [`ROB_WIDTH-1:0] reg_dependency_k
);
  // state and other variables
  localparam FETCH = 0;
  localparam DECODE = 1;
  localparam COMMIT = 2;
  reg [1:0] state;
  reg [31:0] pc;
  // buffer
  // FETCH
  reg [31:0] inst;
  // DECODE
  reg [`ROB_TYPE_WIDTH-1:0] rob_type_buf;
  reg [`RS_TYPE_WIDTH-1:0] rs_type_buf;
  reg [`LSB_TYPE_WIDTH-1:0] lsb_type_buf;
  reg need_rs; // for convenience, every instruction needs rs or lsb, but not both. either of them will commit the instruction to rob
  reg need_j;
  reg need_k;
  reg [31:0] imm_data;
  reg predict;
  reg [31:0] pc_offset;
  // COMMIT
  reg rdy;
  reg [31:0] last_pc;
  // wires
  // DECODE
  localparam LUI = 7'b0110111;
  localparam AUIPC = 7'b0010111;
  localparam JAL = 7'b1101111;
  localparam JALR = 7'b1100111;
  localparam BRANCH = 7'b1100011;
  localparam LOAD = 7'b0000011;
  localparam STORE = 7'b0100011;
  localparam ARITH_IMM = 7'b0010011;
  localparam ARITH_REG = 7'b0110011;
  wire [6:0] opcode = inst[6:0];
  wire [2:0] funct3 = inst[14:12];
  wire [6:0] funct7 = inst[31:25];
  wire [4:0] dest = inst[11:7];
  wire [4:0] reg_id_j = inst[19:15];
  wire [4:0] reg_id_k = inst[24:20];
  wire [31:0] imm_i1 = {{20{inst[31]}}, inst[31:20]};
  wire [31:0] imm_i2 = {{27{inst[24]}}, inst[24:20]};
  wire [31:0] imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]};
  wire [31:0] imm_b = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
  wire [31:0] imm_u = {inst[31:12], 12'b0};
  wire [31:0] imm_j = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
  // COMMIT
  wire full = rob_full || (need_rs && rs_full) || (!need_rs && lsb_full);
  // output
  wire pending_j = need_j && reg_pending_j;
  wire pending_k = need_k && reg_pending_k;

  assign mc_en = state == FETCH;
  assign mc_addr = pc;

  assign rob_rdy = rdy;
  assign rob_type = rob_type_buf;
  assign rob_dest = dest;
  assign rob_inst_addr = last_pc;
  assign rob_predict = predict;
  assign rs_rdy = rdy && need_rs;
  assign rs_type = rs_type_buf;
  assign rs_data_j = reg_data_j;
  assign rs_data_k = reg_data_k;
  assign rs_pending_j = pending_j;
  assign rs_pending_k = pending_k;
  assign rs_dependency_j = reg_dependency_j;
  assign rs_dependency_k = reg_dependency_k;
  assign rs_rob_id = rob_empty_id;
  assign rs_imm = imm_data;
  assign lsb_rdy = rdy && !need_rs;
  assign lsb_type = lsb_type_buf;
  assign lsb_data_j = reg_data_j;
  assign lsb_data_k = reg_data_k;
  assign lsb_pending_j = pending_j;
  assign lsb_pending_k = pending_k;
  assign lsb_dependency_j = reg_dependency_j;
  assign lsb_dependency_k = reg_dependency_k;
  assign lsb_rob_id = rob_empty_id;
  assign lsb_imm = imm_data;
  assign reg_reg_id_j = reg_id_j;
  assign reg_reg_id_k = reg_id_k;
  // cycle
  always @(posedge clk_in) begin
    if (rst_in) begin  // clear
      state <= FETCH;  // start from fetch
      pc <= 0;  // start from 0
      inst <= 0;
      rob_type_buf <= 0;
      rs_type_buf <= 0;
      lsb_type_buf <= 0;
      need_rs <= 0;
      need_j <= 0;
      need_k <= 0;
      imm_data <= 0;
      predict <= 0;
      pc_offset <= 0;
      rdy <= 0;
      last_pc <= 0;
    end else if (!rdy_in) begin  // skip
    end else if (flush) begin  // flush
      // TODO
    end else begin
      case (state)
        FETCH: begin  // wait for memory to be ready
          rdy <= 0;
          if (mc_rdy) begin
            inst  <= mc_data;
            state <= DECODE;
          end
        end
        DECODE: begin // use a tick to decode and do prediction; register data also need a tick to be ready
          case (opcode)  // TODO: specify rob_type, rs_type and lsb_type
            LUI: begin
              need_rs  <= 1;
              need_j   <= 0;
              need_k   <= 0;
              imm_data <= imm_u;
              predict  <= 0;
            end
            AUIPC: begin
              need_rs  <= 1;
              need_j   <= 0;
              need_k   <= 0;
              imm_data <= imm_u;
              predict  <= 0;
            end
            JAL: begin
              need_rs <= 1;
              need_j <= 0;
              need_k <= 0;
              pc_offset <= imm_j;
              predict <= 1;
            end
            JALR: begin
              need_rs  <= 1;
              need_j   <= 1;
              need_k   <= 0;
              imm_data <= imm_i1;
              predict  <= 0;  // JALR should not be predicted as j is not known
            end
            BRANCH: begin
              need_rs <= 1;
              need_j <= 1;
              need_k <= 1;
              pc_offset <= imm_b;
              predict <= 1;  // TODO: branch prediction
            end
            ARITH_IMM: begin
              need_rs  <= 1;
              need_j   <= 1;
              need_k   <= 0;
              imm_data <= (funct3 == 3'b001 || funct3 == 3'b101) ? imm_i2 : imm_i1;
              predict  <= 0;
            end
            ARITH_REG: begin
              need_rs <= 1;
              need_j  <= 1;
              need_k  <= 1;
              predict <= 0;
            end
            LOAD: begin
              need_rs  <= 0;
              need_j   <= 1;
              need_k   <= 0;
              imm_data <= imm_i1;
              predict  <= 0;
            end
            STORE: begin
              need_rs  <= 0;
              need_j   <= 1;
              need_k   <= 1;
              imm_data <= imm_s;
              predict  <= 0;
            end
          endcase
        end
        COMMIT: begin  // commit when ready; update pc and store the old
          if (!full) begin
            rdy <= 1;
            last_pc <= pc;
            pc <= pc + (predict ? pc_offset : 4);
            state <= FETCH;
          end
        end
      endcase
    end
  end
endmodule
