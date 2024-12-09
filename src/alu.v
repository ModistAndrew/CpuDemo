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
    input [`RS_TYPE_WIDTH-1:0] type, // type in reservation station
    output reg rdy, // simply cache en for the next cycle
    output reg [31:0] rob_id_out, // simply cache rob_id_in for the next cycle
    output reg [31:0] result
);
// cycle
    always @(posedge clk_in) begin
        if (rst_in) begin
            rob_id_out <= 0;
            rdy <= 0;
            result <= 0;
        end else if (!rdy_in) begin  // skip
        end else if (flush) begin  // flush
        // TODO
        end else begin
            rob_id_out <= rob_id_in;
            rdy <= en;
        end
    end
endmodule