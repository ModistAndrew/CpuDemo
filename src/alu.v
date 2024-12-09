// calculate the result of the instruction
// take exactly 1 cycle to execute
module Alu(
    input clk_in,
    input rst_in,
    input rdy_in,
    input flush,
    input en,
    input [31:0] rob_id_in,
    input [31:0] data_j,
    input [31:0] data_k,
    input [31:0] imm,
    input [4:0] type, // same as the type in reservation station
    output [31:0] rob_id_out, // simply cache rob_id_in for the next cycle
    output rdy, // simply cache en for the next cycle
    output [31:0] result
);
endmodule