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
    output [3:0] mc_type,
    output [31:0] mc_write_data,
    input mc_rdy,
    input [31:0] mc_read_data,
// instruction from decoder
    output dec_en,
    input dec_rdy,
    input [3:0] dec_type,
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
    input commit_empty,
    input[`ROB_WIDTH-1:0] commit_rob_id,
);
    reg[`LSB_WIDTH-1:0] head, tail;
    reg present[0:`LSB_SIZE-1];
    reg [3:0] type[0:`LSB_SIZE-1];
    reg [31:0] data_j[0:`LSB_SIZE-1];
    reg [31:0] data_k[0:`LSB_SIZE-1];
    reg pending_j[0:`LSB_SIZE-1];
    reg pending_k[0:`LSB_SIZE-1];
    reg [`ROB_WIDTH-1:0] dependency_j[0:`LSB_SIZE-1];
    reg [`ROB_WIDTH-1:0] dependency_k[0:`LSB_SIZE-1];
    reg [`ROB_WIDTH-1:0] rob_id[0:`LSB_SIZE-1];
    reg [31:0] imm[0:`LSB_SIZE-1];
endmodule