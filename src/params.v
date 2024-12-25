`define ROB_SIZE 16
`define ROB_WIDTH 4
`define ROB_TYPE_WIDTH 2 // STORE, REG, BRANCH
`define LSB_SIZE 8
`define LSB_WIDTH 3
`define LSB_TYPE_WIDTH 4 // {isWrite, funct3}
`define RS_SIZE 8
`define RS_WIDTH 3
`define RS_TYPE_WIDTH 6 // {isBr, useImm, funct7[5], funct3} (JALR's isBr and useImm are 1)
`define REG_SIZE 32
`define REG_WIDTH 5
`define IC_SIZE 256
`define IC_WIDTH 8
`define PREDICTOR_SIZE 64
`define PREDICTOR_WIDTH 6
