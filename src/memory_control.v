// manage memory access from load store buffer and decoder
// input: enable and address should be kept valid until rdy is high. after that, data can change
// output: rdy is high and data is valid at exactly the same time
module MemoryControl (
    input clk_in,
    input rst_in,
    input rdy_in,
    input [7:0] mem_din,
    output [7:0] mem_dout,
    output [31:0] mem_a,
    output mem_wr,
    input io_buffer_full,
    output [31:0] dbgreg_dout,
    input flush,
// memory data to decoder
    input dec_en,
    input [31:0] dec_addr,
    output dec_rdy,
    output [31:0] dec_data,
// memory data from/to load store buffer
    input lsb_en,
    input [31:0] lsb_addr,
    input [`LSB_TYPE_WIDTH-1:0] lsb_type, // type in load store buffer
    input [31:0] lsb_write_data,
    output lsb_rdy,
    output [31:0] lsb_read_data
);
    reg [31:0] current_data;
    reg [31:0] current_addr;
    reg wr;
    reg [1:0] state;
endmodule
