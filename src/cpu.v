`include "params.v"
// RISCV32 CPU top module
// port modification allowed for debugging purposes
module cpu(
  	input clk_in, // system clock signal
  	input rst_in, // reset signal
	input rdy_in, // ready signal, pause cpu when low
  	input [7:0] mem_din, // data input bus
  	output [7:0] mem_dout, // data output bus
  	output [31:0] mem_a, // address bus (only 17:0 is used)
  	output mem_wr, // write/read signal (1 for write)
	input io_buffer_full, // 1 if uart buffer is full
	output [31:0] dbgreg_dout // cpu register output (debugging demo)
);
// implementation goes here
	assign dbgreg_dout = 32'd114514;

	wire flush;
	wire dec2mc_en;
	wire [31:0] dec2mc_addr;
	wire mc2dec_rdy;
	wire [31:0] mc2dec_data;
	wire mc2dec_is_compressed;
	wire rob2dec_full;
	wire [`ROB_WIDTH-1:0] rob2dec_rob_empty_id;
	wire dec2rob_rdy;
	wire dec2rob_committable;
	wire [31:0] dec2rob_res;
	wire [`ROB_TYPE_WIDTH-1:0] dec2rob_type;
	wire [`REG_WIDTH-1:0] dec2rob_dest;
	wire [31:0] dec2rob_next_addr;
	wire [31:0] dec2rob_jump_addr;
	wire dec2rob_predict;
	wire [31:0] predict_correct_pc;
	wire rs2dec_full;
	wire dec2rs_rdy;
	wire [`RS_TYPE_WIDTH-1:0] dec2rs_type;
	wire [31:0] dec2rs_data_j;
	wire [31:0] dec2rs_data_k;
	wire dec2rs_pending_j;
	wire dec2rs_pending_k;
	wire [`ROB_WIDTH-1:0] dec2rs_dependency_j;
	wire [`ROB_WIDTH-1:0] dec2rs_dependency_k;
	wire [`ROB_WIDTH-1:0] dec2rs_rob_id;
	wire [31:0] dec2rs_imm;
	wire lsb2dec_full;
	wire dec2lsb_rdy;
	wire [`LSB_TYPE_WIDTH-1:0] dec2lsb_type;
	wire [31:0] dec2lsb_data_j;
	wire [31:0] dec2lsb_data_k;
	wire dec2lsb_pending_j;
	wire dec2lsb_pending_k;
	wire [`ROB_WIDTH-1:0] dec2lsb_dependency_j;
	wire [`ROB_WIDTH-1:0] dec2lsb_dependency_k;
	wire [`ROB_WIDTH-1:0] dec2lsb_rob_id;
	wire [31:0] dec2lsb_imm;
	wire [`REG_WIDTH-1:0] dec2reg_reg_id_j;
	wire [`REG_WIDTH-1:0] dec2reg_reg_id_k;
	wire [31:0] reg2dec_data_j;
	wire [31:0] reg2dec_data_k;
	wire reg2dec_pending_j;
	wire reg2dec_pending_k;
	wire [`ROB_WIDTH-1:0] reg2dec_dependency_j;
	wire [`ROB_WIDTH-1:0] reg2dec_dependency_k;
	wire [`REG_WIDTH-1:0] pending_mark_reg_id;
	wire [`ROB_WIDTH-1:0] pending_mark_rob_id;
	wire branch_result_en;
    wire [`PREDICTOR_WIDTH:1] branch_result_next_pc;
    wire branch_result_taken;
	Decoder decoder(
		.clk_in(clk_in),
		.rst_in(rst_in),
		.rdy_in(rdy_in),
		.flush(flush),
		.mc_en(dec2mc_en),
		.mc_addr(dec2mc_addr),
		.mc_rdy(mc2dec_rdy),
		.mc_data(mc2dec_data),
		.mc_is_compressed(mc2dec_is_compressed),
		.rob_full(rob2dec_full),
		.rob_empty_id(rob2dec_rob_empty_id),
		.rob_rdy(dec2rob_rdy),
		.rob_committable(dec2rob_committable),
		.rob_res(dec2rob_res),
		.rob_type(dec2rob_type),
		.rob_dest(dec2rob_dest),
		.rob_next_addr(dec2rob_next_addr),
		.rob_jump_addr(dec2rob_jump_addr),
		.rob_predict(dec2rob_predict),
		.predict_correct_pc(predict_correct_pc),
		.rs_full(rs2dec_full),
		.rs_rdy(dec2rs_rdy),
		.rs_type(dec2rs_type),
		.rs_data_j(dec2rs_data_j),
		.rs_data_k(dec2rs_data_k),
		.rs_pending_j(dec2rs_pending_j),
		.rs_pending_k(dec2rs_pending_k),
		.rs_dependency_j(dec2rs_dependency_j),
		.rs_dependency_k(dec2rs_dependency_k),
		.rs_rob_id(dec2rs_rob_id),
		.rs_imm(dec2rs_imm),
		.lsb_full(lsb2dec_full),
		.lsb_rdy(dec2lsb_rdy),
		.lsb_type(dec2lsb_type),
		.lsb_data_j(dec2lsb_data_j),
		.lsb_data_k(dec2lsb_data_k),
		.lsb_pending_j(dec2lsb_pending_j),
		.lsb_pending_k(dec2lsb_pending_k),
		.lsb_dependency_j(dec2lsb_dependency_j),
		.lsb_dependency_k(dec2lsb_dependency_k),
		.lsb_rob_id(dec2lsb_rob_id),
		.lsb_imm(dec2lsb_imm),
		.reg_reg_id_j(dec2reg_reg_id_j),
		.reg_reg_id_k(dec2reg_reg_id_k),
		.reg_data_j(reg2dec_data_j),
		.reg_data_k(reg2dec_data_k),
		.reg_pending_j(reg2dec_pending_j),
		.reg_pending_k(reg2dec_pending_k),
		.reg_dependency_j(reg2dec_dependency_j),
		.reg_dependency_k(reg2dec_dependency_k),
		.pending_mark_reg_id(pending_mark_reg_id),
		.pending_mark_rob_id(pending_mark_rob_id),
		.branch_result_en(branch_result_en),
		.branch_result_next_pc(branch_result_next_pc),
		.branch_result_taken(branch_result_taken)
	);
    wire rs2rob_rdy;
    wire [`ROB_WIDTH-1:0] rs2rob_rob_id;
    wire [31:0] rs2rob_data;
    wire rs2rob_set_jump_addr;
    wire rs2alu_en;
    wire [`ROB_WIDTH-1:0] rs2alu_rob_id;
    wire [31:0] rs2alu_data_j;
    wire [31:0] rs2alu_data_k;
    wire [31:0] rs2alu_imm;
    wire [`RS_TYPE_WIDTH-1:0] rs2alu_type;
    wire alu2rs_rdy;
    wire [`ROB_WIDTH-1:0] alu2rs_rob_id_out;
    wire [31:0] alu2rs_result;
    wire alu2rs_set_jump_addr;
    wire rs_broadcast_en;
    wire [`ROB_WIDTH-1:0] rs_broadcast_rob_id;
    wire [31:0] rs_broadcast_data;
    wire lsb_broadcast_en;
    wire [`ROB_WIDTH-1:0] lsb_broadcast_rob_id;
    wire [31:0] lsb_broadcast_data;
	ReservationStation reservation_station(
		.clk_in(clk_in),
		.rst_in(rst_in),
		.rdy_in(rdy_in),
		.flush(flush),
		.dec_full(rs2dec_full),
		.dec_rdy(dec2rs_rdy),
		.dec_type(dec2rs_type),
		.dec_data_j(dec2rs_data_j),
		.dec_data_k(dec2rs_data_k),
		.dec_pending_j(dec2rs_pending_j),
		.dec_pending_k(dec2rs_pending_k),
		.dec_dependency_j(dec2rs_dependency_j),
		.dec_dependency_k(dec2rs_dependency_k),
		.dec_rob_id(dec2rs_rob_id),
		.dec_imm(dec2rs_imm),
		.rob_rdy(rs2rob_rdy),
		.rob_rob_id(rs2rob_rob_id),
		.rob_data(rs2rob_data),
		.rob_set_jump_addr(rs2rob_set_jump_addr),
		.alu_en(rs2alu_en),
		.alu_rob_id(rs2alu_rob_id),
		.alu_data_j(rs2alu_data_j),
		.alu_data_k(rs2alu_data_k),
		.alu_imm(rs2alu_imm),
		.alu_type(rs2alu_type),
		.alu_rdy(alu2rs_rdy),
		.alu_rob_id_out(alu2rs_rob_id_out),
		.alu_result(alu2rs_result),
		.alu_set_jump_addr(alu2rs_set_jump_addr),
		.rs_broadcast_en(rs_broadcast_en),
		.rs_broadcast_rob_id(rs_broadcast_rob_id),
		.rs_broadcast_data(rs_broadcast_data),
		.lsb_broadcast_en(lsb_broadcast_en),
		.lsb_broadcast_rob_id(lsb_broadcast_rob_id),
		.lsb_broadcast_data(lsb_broadcast_data),
		.broadcast_en(rs_broadcast_en),
		.broadcast_rob_id(rs_broadcast_rob_id),
		.broadcast_data(rs_broadcast_data)
	);
	Alu alu(
		.clk_in(clk_in),
		.rst_in(rst_in),
		.rdy_in(rdy_in),
		.flush(flush),
		.en(rs2alu_en),
		.rob_id(rs2alu_rob_id),
		.data_j(rs2alu_data_j),
		.data_k(rs2alu_data_k),
		.imm(rs2alu_imm),
		.type(rs2alu_type),
		.rdy(alu2rs_rdy),
		.rob_id_out(alu2rs_rob_id_out),
		.result(alu2rs_result),
		.set_jump_addr(alu2rs_set_jump_addr)
	);
    wire [`REG_WIDTH-1:0] commit_reg_id;
    wire [31:0] commit_data;
    wire [`ROB_WIDTH-1:0] commit_rob_id;
    wire [`ROB_WIDTH-1:0] reg2rob_rob_id_j;
    wire [`ROB_WIDTH-1:0] reg2rob_rob_id_k;
    wire rob2reg_ready_j;
    wire [31:0] rob2reg_data_j;
    wire rob2reg_ready_k;
    wire [31:0] rob2reg_data_k;
	RegisterFile register_file(
		.clk_in(clk_in),
		.rst_in(rst_in),
		.rdy_in(rdy_in),
		.flush(flush),
		.commit_reg_id(commit_reg_id),
		.commit_data(commit_data),
		.commit_rob_id(commit_rob_id),
		.rob_rob_id_j(reg2rob_rob_id_j),
		.rob_rob_id_k(reg2rob_rob_id_k),
		.rob_ready_j(rob2reg_ready_j),
		.rob_data_j(rob2reg_data_j),
		.rob_ready_k(rob2reg_ready_k),
		.rob_data_k(rob2reg_data_k),
		.dec_reg_id_j(dec2reg_reg_id_j),
		.dec_reg_id_k(dec2reg_reg_id_k),
		.dec_data_j(reg2dec_data_j),
		.dec_data_k(reg2dec_data_k),
		.dec_pending_j(reg2dec_pending_j),
		.dec_pending_k(reg2dec_pending_k),
		.dec_dependency_j(reg2dec_dependency_j),
		.dec_dependency_k(reg2dec_dependency_k),
		.pending_mark_reg_id(pending_mark_reg_id),
		.pending_mark_rob_id(pending_mark_rob_id)
	);
    wire lsb2rob_rdy;
    wire [`ROB_WIDTH-1:0] lsb2rob_rob_id;
    wire [31:0] lsb2rob_data;
    wire commit_info_empty;
    wire [`ROB_WIDTH-1:0] commit_info_current_rob_id;
	ReorderBuffer reorder_buffer(
		.clk_in(clk_in),
		.rst_in(rst_in),
		.rdy_in(rdy_in),
		.flush(flush),
		.dec_full(rob2dec_full),
		.dec_empty_id(rob2dec_rob_empty_id),
		.dec_rdy(dec2rob_rdy),
		.dec_committable(dec2rob_committable),
		.dec_res(dec2rob_res),
		.dec_type(dec2rob_type),
		.dec_dest(dec2rob_dest),
		.dec_next_addr(dec2rob_next_addr),
		.dec_jump_addr(dec2rob_jump_addr),
		.dec_predict(dec2rob_predict),
		.flush_out(flush),
		.predict_correct_pc(predict_correct_pc),
		.commit_reg_id(commit_reg_id),
		.commit_data(commit_data),
		.commit_rob_id(commit_rob_id),
		.reg_rob_id_j(reg2rob_rob_id_j),
		.reg_rob_id_k(reg2rob_rob_id_k),
		.reg_ready_j(rob2reg_ready_j),
		.reg_ready_k(rob2reg_ready_k),
		.reg_data_j(rob2reg_data_j),
		.reg_data_k(rob2reg_data_k),
		.lsb_rdy(lsb2rob_rdy),
		.lsb_rob_id(lsb2rob_rob_id),
		.lsb_data(lsb2rob_data),
		.rs_rdy(rs2rob_rdy),
		.rs_rob_id(rs2rob_rob_id),
		.rs_data(rs2rob_data),
		.rs_set_jump_addr(rs2rob_set_jump_addr),
		.commit_info_empty(commit_info_empty),
		.commit_info_current_rob_id(commit_info_current_rob_id),
		.branch_result_en(branch_result_en),
		.branch_result_next_pc(branch_result_next_pc),
		.branch_result_taken(branch_result_taken)
	);
	wire lsb2mc_en;
    wire [31:0] lsb2mc_addr;
    wire [`LSB_TYPE_WIDTH-1:0] lsb2mc_type;
    wire [31:0] lsb2mc_write_data;
    wire mc2lsb_rdy;
    wire [31:0] mc2lsb_read_data;
	LoadStoreBuffer load_store_buffer(
		.clk_in(clk_in),
		.rst_in(rst_in),
		.rdy_in(rdy_in),
		.flush(flush),
		.mc_en(lsb2mc_en),
		.mc_addr(lsb2mc_addr),
		.mc_type(lsb2mc_type),
		.mc_write_data(lsb2mc_write_data),
		.mc_rdy(mc2lsb_rdy),
		.mc_read_data(mc2lsb_read_data),
		.dec_full(lsb2dec_full),
		.dec_rdy(dec2lsb_rdy),
		.dec_type(dec2lsb_type),
		.dec_data_j(dec2lsb_data_j),
		.dec_data_k(dec2lsb_data_k),
		.dec_pending_j(dec2lsb_pending_j),
		.dec_pending_k(dec2lsb_pending_k),
		.dec_dependency_j(dec2lsb_dependency_j),
		.dec_dependency_k(dec2lsb_dependency_k),
		.dec_rob_id(dec2lsb_rob_id),
		.dec_imm(dec2lsb_imm),
		.rob_rdy(lsb2rob_rdy),
		.rob_rob_id(lsb2rob_rob_id),
		.rob_data(lsb2rob_data),
		.rs_broadcast_en(rs_broadcast_en),
		.rs_broadcast_rob_id(rs_broadcast_rob_id),
		.rs_broadcast_data(rs_broadcast_data),
		.lsb_broadcast_en(lsb_broadcast_en),
		.lsb_broadcast_rob_id(lsb_broadcast_rob_id),
		.lsb_broadcast_data(lsb_broadcast_data),
		.broadcast_en(lsb_broadcast_en),
		.broadcast_rob_id(lsb_broadcast_rob_id),
		.broadcast_data(lsb_broadcast_data),
		.commit_info_empty(commit_info_empty),
		.commit_info_current_rob_id(commit_info_current_rob_id)
	);
    wire [31:1] read_ic_addr;
    wire read_ic_rdy;
    wire [31:0] read_ic_data;
    wire read_ic_is_compressed;
    wire write_ic_rdy;
    wire [31:1] write_ic_addr;
    wire [31:0] write_ic_data;
    wire write_ic_is_compressed;
	MemoryControl memory_control(
		.clk_in(clk_in),
		.rst_in(rst_in),
		.rdy_in(rdy_in),
		.mem_din(mem_din),
		.mem_dout(mem_dout),
		.mem_a_out(mem_a),
		.mem_wr_out(mem_wr),
		.io_buffer_full(io_buffer_full),
		.flush(flush),
		.dec_en(dec2mc_en),
		.dec_addr(dec2mc_addr),
		.dec_rdy(mc2dec_rdy),
		.dec_data(mc2dec_data),
		.dec_is_compressed(mc2dec_is_compressed),
		.lsb_en(lsb2mc_en),
		.lsb_addr(lsb2mc_addr),
		.lsb_type(lsb2mc_type),
		.lsb_write_data(lsb2mc_write_data),
		.lsb_rdy(mc2lsb_rdy),
		.lsb_read_data(mc2lsb_read_data),
		.read_ic_addr(read_ic_addr),
		.read_ic_rdy(read_ic_rdy),
		.read_ic_data(read_ic_data),
		.read_ic_is_compressed(read_ic_is_compressed),
		.write_ic_rdy(write_ic_rdy),
		.write_ic_addr(write_ic_addr),
		.write_ic_data(write_ic_data),
		.write_ic_is_compressed(write_ic_is_compressed)
	);
	InstructionCache instruction_cache(
		.clk_in(clk_in),
		.rst_in(rst_in),
		.rdy_in(rdy_in),
		.read_ic_addr(read_ic_addr),
		.read_ic_rdy(read_ic_rdy),
		.read_ic_data(read_ic_data),
		.read_ic_is_compressed(read_ic_is_compressed),
		.write_ic_rdy(write_ic_rdy),
		.write_ic_addr(write_ic_addr),
		.write_ic_data(write_ic_data),
		.write_ic_is_compressed(write_ic_is_compressed)
	);
// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)
endmodule