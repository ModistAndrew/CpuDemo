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
    output [31:0] mem_a_out,
    output mem_wr_out,
    input io_buffer_full,
    input flush,
// memory data to decoder
    input dec_en,
    input [31:0] dec_addr,
    output reg dec_rdy,
    output [31:0] dec_data,
    output dec_is_compressed,
// memory data from/to load store buffer
    input lsb_en,
    input [31:0] lsb_addr,
    input [`LSB_TYPE_WIDTH-1:0] lsb_type, // type as in load store buffer
    input [31:0] lsb_write_data,
    output reg lsb_rdy,
    output [31:0] lsb_read_data,
    // data from instruction cache
    output [31:1] read_ic_addr,
    input read_ic_rdy,
    input [31:0] read_ic_data,
    input read_ic_is_compressed,
    // data to instruction cache
    output reg write_ic_rdy,
    output [31:1] write_ic_addr,
    output [31:0] write_ic_data,
    output write_ic_is_compressed
);
    localparam SELECT = 0;
    localparam DECODER_0 = 1;
    localparam DECODER_1 = 2;
    localparam DECODER_2 = 3;
    localparam DECODER_3 = 4;
    localparam DECODER_4 = 5;
    localparam DECODER_DECOMPRESS = 6;
    localparam LSB_0 = 7;
    localparam LSB_1 = 8;
    localparam LSB_2 = 9;
    localparam LSB_3 = 10;
    localparam LSB_4 = 11;
    localparam COOLDOWN = 12;
    reg [3:0] state;
// buffer
    reg [31:0] current_data;
    reg is_compressed;
    reg mem_en;
    reg [31:0] mem_a;
    reg mem_wr;
// wires
    wire lsb_wr = lsb_type[3];
    wire lsb_larger_than_byte = lsb_type[1] || lsb_type[0];
    wire lsb_larger_than_half = lsb_type[1];
    wire lsb_sign_extend = !lsb_type[2];
    wire [31:0] mem_din_extended = {{24{mem_din[7] && lsb_sign_extend}}, mem_din};
    // compressed instruction
    wire uncompressed = mem_din[1] && mem_din[0];
    wire [15:0] compressed_inst = {mem_din, current_data[7:0]};
    wire [4:0] r_4_2 = {2'b01, compressed_inst[4:2]};
    wire [4:0] r_9_7 = {2'b01, compressed_inst[9:7]};
    wire [4:0] r_11_7 = compressed_inst[11:7];
    wire [4:0] r_6_2 = compressed_inst[6:2];
    wire [11:0] imm_12_6_2_extended = {{7{compressed_inst[12]}}, compressed_inst[6:2]};
    wire [11:0] ls_imm_extended = {5'b00000, compressed_inst[5], compressed_inst[12:10], compressed_inst[6], 2'b00};
    wire [11:0] addi4spn_imm_extended = {2'b00, compressed_inst[10:7], compressed_inst[12:11], compressed_inst[5], compressed_inst[6], 2'b00};
    wire [11:0] addi16sp_imm_extended = {{3{compressed_inst[12]}}, compressed_inst[4:3], compressed_inst[5], compressed_inst[2], compressed_inst[6], 4'b0000};
    wire [20:0] j_imm_extended = {{10{compressed_inst[12]}}, compressed_inst[8], compressed_inst[10:9], compressed_inst[6], compressed_inst[7], compressed_inst[2], compressed_inst[11], compressed_inst[5:3], 1'b0};
    wire [12:0] bz_imm_extended = {{5{compressed_inst[12]}}, compressed_inst[6:5], compressed_inst[2], compressed_inst[11:10], compressed_inst[4:3], 1'b0};
    wire [11:0] lwsp_imm_extended = {4'b0000, compressed_inst[3:2], compressed_inst[12], compressed_inst[6:4], 2'b00};
    wire [11:0] swsp_imm_extended = {4'b0000, compressed_inst[8:7], compressed_inst[12:9], 2'b00};
// output
    assign dec_data = current_data;
    assign dec_is_compressed = is_compressed;
    assign lsb_read_data = current_data;
    assign read_ic_addr = dec_addr[31:1];
    assign write_ic_addr = dec_addr[31:1];
    assign write_ic_data = current_data;
    assign write_ic_is_compressed = is_compressed;
    assign mem_a_out = mem_en ? mem_a : 0;
    assign mem_wr_out = mem_en && mem_wr;
// cycle
    always @(posedge clk_in) begin
        if (rst_in || flush && rdy_in) begin
            state <= SELECT;
            current_data <= 0;
            is_compressed <= 0;
            dec_rdy <= 0;
            lsb_rdy <= 0;
            write_ic_rdy <= 0;
            mem_dout <= 0;
            mem_en <= 0;
            mem_a <= 0;
            mem_wr <= 0;
        end else if (rdy_in) begin
            case (state)
                SELECT: begin
                    if (lsb_en && !io_buffer_full) begin // lsb is of higher priority
                        state <= LSB_0;
                        mem_dout <= lsb_write_data[7:0];
                        mem_en <= 1;
                        mem_a <= lsb_addr;
                        mem_wr <= lsb_wr;
                    end else if (dec_en) begin
                        if (read_ic_rdy) begin
                            state <= COOLDOWN;
                            dec_rdy <= 1;
                            current_data <= read_ic_data;
                            is_compressed <= read_ic_is_compressed;
                        end else begin
                            mem_en <= 1;
                            state <= DECODER_0;
                            mem_a <= dec_addr;
                            mem_wr <= 0;
                        end
                    end
                end
                DECODER_0: begin
                    state <= DECODER_1;
                    mem_a <= mem_a + 1;
                end
                DECODER_1: begin
                    state <= uncompressed ? DECODER_2 : DECODER_DECOMPRESS;
                    current_data <= mem_din_extended;
                    mem_a <= mem_a + 1;
                    mem_en <= uncompressed;
                end
                DECODER_2: begin
                    state <= DECODER_3;
                    current_data <= {mem_din_extended[23:0], current_data[7:0]};
                    mem_a <= mem_a + 1;
                end
                DECODER_3: begin
                    state <= DECODER_4;
                    current_data <= {mem_din_extended[15:0], current_data[15:0]};
                    mem_en <= 0;
                end
                DECODER_4: begin
                    state <= COOLDOWN;
                    current_data <= {mem_din_extended[7:0], current_data[23:0]};
                    is_compressed <= 0;
                    dec_rdy <= 1;
                    write_ic_rdy <= 1;
                end
                DECODER_DECOMPRESS: begin
                    state <= COOLDOWN;
                    dec_rdy <= 1;
                    write_ic_rdy <= 1;
                    is_compressed <= 1;
                    case (compressed_inst[1:0])
                        2'b00: case (compressed_inst[15:13])
                            // addi4spn: addi rd, x2, nzuimm
                            3'b000: current_data <= {addi4spn_imm_extended, 5'b00010, 3'b000, r_4_2, 7'b0010011};
                            // lw: lw rd, nzuimm(rs1)
                            3'b010: current_data <= {ls_imm_extended, r_9_7, 3'b010, r_4_2, 7'b0000011};
                            // sw: sw rs2, nzuimm(rs1)
                            3'b110: current_data <= {ls_imm_extended[11:5], r_4_2, r_9_7, 3'b010, ls_imm_extended[4:0], 7'b0100011};
                        endcase
                        2'b01: case (compressed_inst[15:13])
                            3'b100: case (compressed_inst[11:10])
                                // srli: srli rd, rd, imm
                                2'b00: current_data <= {7'b0000000, imm_12_6_2_extended[4:0], r_9_7, 3'b101, r_9_7, 7'b0010011};
                                // srai: srai rd, rd, imm
                                2'b01: current_data <= {7'b0100000, imm_12_6_2_extended[4:0], r_9_7, 3'b101, r_9_7, 7'b0010011};
                                // andi: andi rd, rd, imm
                                2'b10: current_data <= {imm_12_6_2_extended, r_9_7, 3'b111, r_9_7, 7'b0010011};
                                2'b11: case (compressed_inst[6:5])
                                    // sub: sub rd, rd, rs2
                                    2'b00: current_data <= {7'b0100000, r_4_2, r_9_7, 3'b000, r_9_7, 7'b0110011};
                                    // xor: xor rd, rd, rs2
                                    2'b01: current_data <= {7'b0000000, r_4_2, r_9_7, 3'b100, r_9_7, 7'b0110011};
                                    // or: or rd, rd, rs2
                                    2'b10: current_data <= {7'b0000000, r_4_2, r_9_7, 3'b110, r_9_7, 7'b0110011};
                                    // and: and rd, rd, rs2
                                    2'b11: current_data <= {7'b0000000, r_4_2, r_9_7, 3'b111, r_9_7, 7'b0110011};
                                endcase
                            endcase
                            // addi: addi rd, rd, imm
                            3'b000: current_data <= {imm_12_6_2_extended, r_11_7, 3'b000, r_11_7, 7'b0010011};
                            // li: addi rd, x0, imm
                            3'b010: current_data <= {imm_12_6_2_extended, 5'b00000, 3'b000, r_11_7, 7'b0010011};
                            // addi16sp: addi x2, x2, imm
                            // lui: lui rd, imm
                            3'b011: current_data <= r_11_7 == 5'b00010 ? 
                            {addi16sp_imm_extended, 5'b00010, 3'b000, 5'b00010, 7'b0010011} : 
                            {{8{imm_12_6_2_extended[11]}}, imm_12_6_2_extended, r_11_7, 7'b0110111};
                            // jal: jal x1, imm
                            3'b001: current_data <= {j_imm_extended[20], j_imm_extended[10:1], j_imm_extended[11], j_imm_extended[19:12], 5'b00001, 7'b1101111};
                            // j: jal x0, imm
                            3'b101: current_data <= {j_imm_extended[20], j_imm_extended[10:1], j_imm_extended[11], j_imm_extended[19:12], 5'b00000, 7'b1101111};
                            // beqz: beqz rs1, imm
                            3'b110: current_data <= {bz_imm_extended[12], bz_imm_extended[10:5], r_9_7, 5'b00000, 3'b000, bz_imm_extended[4:1], bz_imm_extended[11], 7'b1100011};
                            // bnez: bnez rs1, imm
                            3'b111: current_data <= {bz_imm_extended[12], bz_imm_extended[10:5], r_9_7, 5'b00000, 3'b001, bz_imm_extended[4:1], bz_imm_extended[11], 7'b1100011};
                        endcase
                        2'b10: case (compressed_inst[15:13])
                            // slli: slli rd, rd, imm
                            3'b000: current_data <= {7'b0000000, imm_12_6_2_extended[4:0], r_11_7, 3'b001, r_11_7, 7'b0010011};
                            // lwsp: lw rd, imm(x2)
                            3'b010: current_data <= {lwsp_imm_extended, 5'b00010, 3'b010, r_11_7, 7'b0000011};
                            // swsp: sw rs2, imm(x2)
                            3'b110: current_data <= {swsp_imm_extended[11:5], r_6_2, 5'b00010, 3'b010, swsp_imm_extended[4:0], 7'b0100011};
                            3'b100: case (compressed_inst[12])
                                // jr: jalr x0, rs1, 0
                                // mv: add rd, x0, rs2
                                1'b0: current_data <= r_6_2 == 5'b00000 ? 
                                {12'b000000000000, r_11_7, 3'b000, 5'b00000, 7'b1100111} :
                                {7'b0000000, r_6_2, 5'b00000, 3'b000, r_11_7, 7'b0110011};
                                // jalr: jalr x1, rs1, 0
                                // add: add rd, rd, rs2
                                1'b1: current_data <= r_6_2 == 5'b00000 ? 
                                {12'b000000000000, r_11_7, 3'b000, 5'b00001, 7'b1100111} :
                                {7'b0000000, r_6_2, r_11_7, 3'b000, r_11_7, 7'b0110011};
                            endcase
                        endcase
                    endcase
                end
                LSB_0: begin
                    state <= LSB_1;
                    mem_dout <= lsb_write_data[15:8];
                    mem_a <= mem_a + 1;
                    mem_en <= lsb_larger_than_byte; // if lsb is larger than byte, continue writing
                end
                LSB_1: begin
                    state <= lsb_larger_than_byte ? LSB_2 : COOLDOWN;
                    current_data <= mem_din_extended;
                    lsb_rdy <= !lsb_larger_than_byte;
                    mem_dout <= lsb_write_data[23:16];
                    mem_a <= mem_a + 1;
                    mem_en <= lsb_larger_than_half; // if lsb is larger than half, continue writing
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
                    mem_en <= 0;
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
                    write_ic_rdy <= 0;
                end
            endcase
        end
    end
endmodule
