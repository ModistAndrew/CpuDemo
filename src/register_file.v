// store register values and status
// in charge of checking dependencies and forwarding data
module RegisterFile(
    input clk_in,
    input rst_in,
    input rdy_in,
    input flush,
// commit from reorder buffer
    input[`REG_WIDTH-1:0] commit_reg_id, // no enable flag needed: set to 0 when not in use
    input[31:0] commit_data,
    input[`ROB_WIDTH-1:0] commit_rob_id, // use rob index to check whether the register should be updated
// register data from reorder buffer
    output[`ROB_WIDTH-1:0] rob_rob_id_j,
    input rob_ready_j,
    input[31:0] rob_data_j,
    output[`ROB_WIDTH-1:0] rob_rob_id_k,
    input rob_ready_k,
    input[31:0] rob_data_k,
// register data to decoder
    input[`REG_WIDTH-1:0] dec_reg_id_j,
    input[`REG_WIDTH-1:0] dec_reg_id_k,
    output[31:0] dec_data_j,
    output[31:0] dec_data_k,
    output dec_pending_j,
    output dec_pending_k,
    output[`ROB_WIDTH-1:0] dec_dependency_j,
    output[`ROB_WIDTH-1:0] dec_dependency_k,
);
    reg[31:0] reg[0:`REG_SIZE-1];
    reg pending[0:`REG_SIZE-1];
    reg[`ROB_WIDTH-1:0] dependency[0:`REG_SIZE-1];
endmodule