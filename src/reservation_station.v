// store and execute instructions
// find the nearest executable instruction and execute it
module ReservationStation(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    input flush,
// instruction from decoder
    output dec_en,
    input dec_rdy,
    input [4:0] dec_type,
    input [31:0] dec_data_j,
    input [31:0] dec_data_k,
    input dec_pending_j,
    input dec_pending_k,
    input [`ROB_WIDTH-1:0] dec_dependency_j,
    input [`ROB_WIDTH-1:0] dec_dependency_k,
    input [`ROB_WIDTH-1:0] dec_rob_id,
// data to reorder buffer
    input rob_en,
    output rob_rdy,
    output [`ROB_WIDTH-1:0] rob_rob_id,
    output [31:0] rob_data,
// data from alu
    output alu_en,
    input[31:0] alu_data_j,
    input[31:0] alu_data_k,
    input[31:0] alu_true_result,
    input[31:0] alu_false_result,
    input[4:0] alu_type,
    input alu_rdy,
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
    output [31:0] broadcast_data,
);
    reg[`RS_WIDTH-1:0] head, tail;
    reg present[0:`RS_SIZE-1];
    reg [4:0] type[0:`RS_SIZE-1];
    reg [31:0] data_j[0:`RS_SIZE-1];
    reg [31:0] data_k[0:`RS_SIZE-1];
    reg pending_j[0:`RS_SIZE-1];
    reg pending_k[0:`RS_SIZE-1];
    reg [`ROB_WIDTH-1:0] dependency_j[0:`RS_SIZE-1];
    reg [`ROB_WIDTH-1:0] dependency_k[0:`RS_SIZE-1];
    reg [`ROB_WIDTH-1:0] rob_id[0:`RS_SIZE-1];
    reg [31:0] imm[0:`RS_SIZE-1];
endmodule