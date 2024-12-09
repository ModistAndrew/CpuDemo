// calculate the result of the instruction
module Alu(
    input clk_in,
    input rst_in,
    input rdy_in,
    input flush,
    input en,
    input [31:0] data_j,
    input [31:0] data_k,
    input [31:0] true_result,
    input [31:0] false_result,
    input [4:0] type,
    output rdy,
    output [31:0] result
);
endmodule