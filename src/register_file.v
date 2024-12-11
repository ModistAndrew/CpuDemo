`include "params.v"
// store register values and status
// in charge of checking dependencies and forwarding data
module RegisterFile(
    input clk_in,
    input rst_in,
    input rdy_in,
    input flush,
// commit from reorder buffer
    input [`REG_WIDTH-1:0] commit_reg_id, // no enable flag needed: set to 0 when not in use
    input [31:0] commit_data,
    input [`ROB_WIDTH-1:0] commit_rob_id, // use rob index to check whether the register should be updated
// register data from reorder buffer
    output [`ROB_WIDTH-1:0] rob_rob_id_j,
    output [`ROB_WIDTH-1:0] rob_rob_id_k,
    input rob_ready_j,
    input [31:0] rob_data_j,
    input rob_ready_k,
    input [31:0] rob_data_k,
// register data to decoder
    input [`REG_WIDTH-1:0] dec_reg_id_j,
    input [`REG_WIDTH-1:0] dec_reg_id_k,
    output [31:0] dec_data_j,
    output [31:0] dec_data_k,
    output dec_pending_j,
    output dec_pending_k,
    output [`ROB_WIDTH-1:0] dec_dependency_j,
    output [`ROB_WIDTH-1:0] dec_dependency_k,
// pending mark from decoder
    input [`REG_WIDTH-1:0] pending_mark_reg_id,
    input [`ROB_WIDTH-1:0] pending_mark_rob_id
);
    reg [31:0] data[0:`REG_SIZE-1];
    reg pending[0:`REG_SIZE-1];
    reg [`ROB_WIDTH-1:0] dependency[0:`REG_SIZE-1];
// wires
    wire search_pending_j = pending[dec_reg_id_j];
    wire search_pending_k = pending[dec_reg_id_k];
    wire [`ROB_WIDTH-1:0] search_dependency_j = dependency[dec_reg_id_j];
    wire [`ROB_WIDTH-1:0] search_dependency_k = dependency[dec_reg_id_k];
// output
    assign rob_rob_id_j = search_dependency_j;
    assign rob_rob_id_k = search_dependency_k;
    assign dec_data_j = search_pending_j ? rob_data_j : data[dec_reg_id_j];
    assign dec_data_k = search_pending_k ? rob_data_k : data[dec_reg_id_k];
    assign dec_pending_j = search_pending_j && !rob_ready_j;
    assign dec_pending_k = search_pending_k && !rob_ready_k;
    assign dec_dependency_j = search_dependency_j;
    assign dec_dependency_k = search_dependency_k;
    // don't have to deal with commit here as rob data is still valid when commit
    // also, don't have to deal with pending mark here: pending mark should take effect in the next cycle
// cycle
    always @(posedge clk_in) begin: Main
        integer i;
        if (rst_in || flush && rdy_in) begin
            for (i = 0; i < `REG_SIZE; i = i + 1) begin
                pending[i] <= 0;
                dependency[i] <= 0;
                if (rst_in) begin
                    data[i] <= 0; // flush will not reset data
                end
            end
        end else if (rdy_in) begin
            if (commit_reg_id != 0) begin
                data[commit_reg_id] <= commit_data;
                // if mark pending at the same time, do not clear
                if (dependency[commit_reg_id] == commit_rob_id && commit_reg_id != pending_mark_reg_id) begin
                    pending[commit_reg_id] <= 0;
                end
            end
            if (pending_mark_reg_id != 0) begin
                pending[pending_mark_reg_id] <= 1;
                dependency[pending_mark_reg_id] <= pending_mark_rob_id;
            end
        end
    end
    wire [31:0] zero = data[0];
    wire [31:0] ra = data[1];
    wire [31:0] sp = data[2];
    wire [31:0] gp = data[3];
    wire [31:0] tp = data[4];
    wire [31:0] t0 = data[5];
    wire [31:0] t1 = data[6];
    wire [31:0] t2 = data[7];
    wire [31:0] s0 = data[8];
    wire [31:0] s1 = data[9];
    wire [31:0] a0 = data[10];
    wire [31:0] a1 = data[11];
    wire [31:0] a2 = data[12];
    wire [31:0] a3 = data[13];
    wire [31:0] a4 = data[14];
    wire [31:0] a5 = data[15];
    wire [31:0] a6 = data[16];
    wire [31:0] a7 = data[17];
    wire [31:0] s2 = data[18];
    wire [31:0] s3 = data[19];
    wire [31:0] s4 = data[20];
    wire [31:0] s5 = data[21];
    wire [31:0] s6 = data[22];
    wire [31:0] s7 = data[23];
    wire [31:0] s8 = data[24];
    wire [31:0] s9 = data[25];
    wire [31:0] s10 = data[26];
    wire [31:0] s11 = data[27];
    wire [31:0] t3 = data[28];
    wire [31:0] t4 = data[29];
    wire [31:0] t5 = data[30];
    wire [31:0] t6 = data[31];
endmodule