`include "params.v"
module InstructionCache(
    input clk_in,
    input rst_in,
    input rdy_in,
    // data to memory control
    input [31:0] read_ic_addr,
    output read_ic_rdy,
    output [31:0] read_ic_data,
    output read_ic_is_compressed,
    // data from memory control
    input write_ic_rdy,
    input [31:0] write_ic_addr,
    input [31:0] write_ic_data,
    input write_ic_is_compressed
);
    reg present[0:`IC_SIZE-1];
    reg [31-`IC_WIDTH-1:0] tag[0:`IC_SIZE-1];
    reg [31:0] data[0:`IC_SIZE-1];
    reg is_compressed[0:`IC_SIZE-1];
// wires
    wire [`IC_WIDTH-1:0] search_index = read_ic_addr[`IC_WIDTH:1];
    wire [31-`IC_WIDTH-1:0] search_tag = read_ic_addr[31:`IC_WIDTH+1];
    wire [`IC_WIDTH-1:0] modify_index = write_ic_addr[`IC_WIDTH:1];
    wire [31-`IC_WIDTH-1:0] modify_tag = write_ic_addr[31:`IC_WIDTH+1]; // last bit is always 0
// output
    assign read_ic_rdy = present[search_index] && tag[search_index] == search_tag;
    assign read_ic_data = data[search_index];
    assign read_ic_is_compressed = is_compressed[search_index]; // use combinational logic
// cycle
    always @(posedge clk_in) begin: Main
        integer i;
        if (rst_in) begin
            for (i = 0; i < `IC_SIZE; i = i + 1) begin
                present[i] <= 0;
                tag[i] <= 0;
                data[i] <= 0;
                is_compressed[i] <= 0;
            end
        end else if (rdy_in) begin
            if (write_ic_rdy) begin
                present[modify_index] <= 1;
                tag[modify_index] <= modify_tag;
                data[modify_index] <= write_ic_data;
                is_compressed[modify_index] <= write_ic_is_compressed;
            end
        end
    end
endmodule