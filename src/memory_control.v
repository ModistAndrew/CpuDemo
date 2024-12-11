`include "params.v"
// manage memory access from load store buffer and decoder
// input: enable and address should be kept valid until rdy is high. after that, input should update in the next cycle
// output: rdy is high and data is valid for exactly one cycle
module MemoryControl (
    input clk_in,
    input rst_in,
    input rdy_in,
    input [7:0] mem_din,
    output reg [7:0] mem_dout,
    output reg [31:0] mem_a,
    output reg mem_wr,
    input io_buffer_full,
    output [31:0] dbgreg_dout,
    input flush,
// memory data to decoder
    input dec_en,
    input [31:0] dec_addr,
    output reg dec_rdy,
    output [31:0] dec_data,
// memory data from/to load store buffer
    input lsb_en,
    input [31:0] lsb_addr,
    input [`LSB_TYPE_WIDTH-1:0] lsb_type, // type as in load store buffer
    input [31:0] lsb_write_data,
    output reg lsb_rdy,
    output [31:0] lsb_read_data
);
    localparam SELECT = 0;
    localparam DECODER_0 = 1;
    localparam DECODER_1 = 2;
    localparam DECODER_2 = 3;
    localparam DECODER_3 = 4;
    localparam DECODER_4 = 5;
    localparam LSB_0 = 6;
    localparam LSB_1 = 7;
    localparam LSB_2 = 8;
    localparam LSB_3 = 9;
    localparam LSB_4 = 10;
    localparam COOLDOWN = 11;
    reg [3:0] state;
// buffer
    reg [31:0] current_data;
// wires
    wire lsb_wr = lsb_type[3];
    wire lsb_larger_than_byte = lsb_type[1] || lsb_type[0];
    wire lsb_larger_than_half = lsb_type[1];
    wire lsb_sign_extend = lsb_type[2];
    wire [31:0] mem_din_extended = {{24{mem_din[7] && lsb_sign_extend}}, mem_din};
// output
    assign dec_data = current_data;
    assign lsb_read_data = current_data;
// cycle
    always @(posedge clk_in) begin
        if (rst_in || flush && rdy_in) begin
            state <= SELECT;
            current_data <= 0;
            dec_rdy <= 0;
            lsb_rdy <= 0;
            mem_dout <= 0;
            mem_a <= 0;
            mem_wr <= 0;
        end else if (rdy_in && !io_buffer_full) begin
            case (state)
                SELECT: begin
                    if (lsb_en) begin // lsb is of higher priority
                        state <= LSB_0;
                        mem_dout <= lsb_write_data[7:0];
                        mem_a <= lsb_addr;
                        mem_wr <= lsb_wr;
                    end else if (dec_en) begin
                        state <= DECODER_0;
                        mem_a <= dec_addr;
                    end
                end
                DECODER_0: begin
                    state <= DECODER_1;
                    mem_a <= mem_a + 1;
                end
                DECODER_1: begin
                    state <= DECODER_2;
                    current_data <= mem_din_extended;
                    mem_a <= mem_a + 1;
                end
                DECODER_2: begin
                    state <= DECODER_3;
                    current_data <= {mem_din_extended[23:0], current_data[7:0]};
                    mem_a <= mem_a + 1;
                end
                DECODER_3: begin
                    state <= DECODER_4;
                    current_data <= {mem_din_extended[15:0], current_data[15:0]};
                end
                DECODER_4: begin
                    state <= COOLDOWN;
                    current_data <= {mem_din_extended[7:0], current_data[23:0]};
                    dec_rdy <= 1;
                end
                LSB_0: begin
                    state <= LSB_1;
                    mem_dout <= lsb_write_data[15:8];
                    mem_a <= mem_a + 1;
                    mem_wr <= mem_wr && lsb_larger_than_byte; // if lsb is larger than byte, continue writing
                end
                LSB_1: begin
                    state <= lsb_larger_than_byte ? LSB_2 : COOLDOWN;
                    current_data <= mem_din_extended;
                    lsb_rdy <= !lsb_larger_than_byte;
                    mem_dout <= lsb_write_data[23:16];
                    mem_a <= mem_a + 1;
                    mem_wr <= mem_wr && lsb_larger_than_half; // if lsb is larger than half, continue writing
                end
                LSB_2: begin
                    state <= lsb_larger_than_half ? LSB_3 : COOLDOWN;
                    current_data <= {mem_din_extended[23:0], current_data[7:0]};
                    lsb_rdy <= !lsb_larger_than_half;
                    mem_dout <= lsb_write_data[31:24];
                    mem_a <= mem_a + 1;
                end
                LSB_3: begin
                    state <= LSB_4;
                    current_data <= {mem_din_extended[15:0], current_data[15:0]};
                    mem_wr <= 0;
                end
                LSB_4: begin
                    state <= COOLDOWN;
                    current_data <= {mem_din_extended[7:0], current_data[23:0]};
                    lsb_rdy <= 1;
                end
                COOLDOWN: begin // wait for rdy to go low
                    state <= SELECT;
                    dec_rdy <= 0;
                    lsb_rdy <= 0;
                end
            endcase
        end
    end
endmodule
