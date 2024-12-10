`include "params.v"
// calculate the result of the instruction
// take exactly 1 cycle to execute
module Alu(
    input clk_in,
    input rst_in,
    input rdy_in,
    input flush,
    input en,
    input [31:0] rob_id,
    input [31:0] data_j,
    input [31:0] data_k,
    input [31:0] imm,
    input [`RS_TYPE_WIDTH-1:0] type, // type as in reservation station
    output reg rdy, // simply cache en for the next cycle
    output reg [31:0] rob_id_out, // simply cache rob_id_in for the next cycle
    output reg [31:0] result,
    output reg set_jump_addr // for JALR
);
// wires
    wire [31:0] k_or_imm = type[4] ? imm : data_k;
// cycle
    always @(posedge clk_in) begin
        if (rst_in || flush && rdy_in) begin
            rob_id_out <= 0;
            rdy <= 0;
            result <= 0;
            set_jump_addr <= 0;
        end else if (rdy_in) begin
            rob_id_out <= rob_id;
            rdy <= en;
            set_jump_addr <= type[5] && type[4];
            if (type[5]) begin
                if (type[4]) begin
                    result <= data_j + imm;
                end else begin
                    case (type[3:1])
                        3'b000: result <= data_j == data_k;
                        3'b001: result <= data_j != data_k;
                        3'b100: result <= $signed(data_j) < $signed(data_k);
                        3'b110: result <= data_j < data_k;
                        3'b101: result <= $signed(data_j) >= $signed(data_k);
                        3'b111: result <= data_j >= data_k;
                    endcase
                end
            end else begin
                case (type[3:1])
                    3'b000: result <= type[0] ? data_j - k_or_imm : data_j + k_or_imm;
                    3'b001: result <= data_j << k_or_imm[4:0];
                    3'b010: result <= $signed(data_j) < $signed(k_or_imm);
                    3'b011: result <= data_j < k_or_imm;
                    3'b100: result <= data_j ^ k_or_imm;
                    3'b101: result <= type[0] ? data_j >>> k_or_imm[4:0] : data_j >> k_or_imm[4:0];
                    3'b110: result <= data_j | k_or_imm;
                    3'b111: result <= data_j & k_or_imm;
                endcase
            end
        end
    end
endmodule