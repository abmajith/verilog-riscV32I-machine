module processor(
  // clock signal
  input clk,
  // reset signal active high
  input rst);
  
  // program counter act as instruction address
  reg [31:0] PC;

  // for holding current instruction and its validity
  wire [31:0] inst;
  wire        isValidInst;

  // couple of wires to hold current instruction fields signals
  wire [6:0] opCode;
  wire [2:0] funct3;
  wire [6:0] funct7;
  wire [31:0] immediate_value;
  
  // register source and destination address and its mode signals for the current instruction
  wire [4:0] rs1_ad;
  wire [4:0] rs2_ad;
  wire [4:0] rd_ad;

  wire is_wr_en; // destination register write
  wire is_rd_en1; // first register source read
  wire is_rd_en2; // second register source read

  // based on opcode, hold instruction type by assign the following wires
  wire is_alu_reg  = (inst[6:0] == 7'b0110011);
  wire is_alu_imm  = (inst[6:0] == 7'b0010011);
  wire is_load     = (inst[6:0] == 7'b0000011);
  wire is_store    = (inst[6:0] == 7'b0100011);
  wire is_branch   = (inst[6:0] == 7'b1100011);
  wire is_jalr     = (inst[6:0] == 7'b1100111);
  wire is_jal      = (inst[6:0] == 7'b1101111);
  wire is_lui      = (inst[6:0] == 7'b0110111);
  wire is_auipc    = (inst[6:0] == 7'b0010111);
  wire is_system   = (inst[6:0] == 7'b1110011);
  wire is_fence    = (inst[6:0] == 7'b0001111);
  wire is_invalid  = (isValidInst || is_fence ||  // you are correct, we are not dealing with fence instruction!
                          !(
                            is_alu_reg || is_alu_imm || is_load || is_store || 
                            is_branch || is_jalr || is_jal || is_lui || is_auipc || is_system
                           )
                     );
  
  // instruction memory

  ByteAlignInstructionMemory #(
        .START_ADDRESS(0),
        .STOP_ADDRESS(1023) // holds block of 1KB memory, which can hold upto 256 RV32I instructions
      ) instMem (
        // clock signals
        .clk(clk),

        // instruction address
        .iaddr(PC),
        .instruction(inst),
        .isValid(isValidInst)
      );

  // create a decode module instance 
  decode instDecoder (
    // instruction wiring
    .instruction(inst),

    // register address and mode circuit wiring
    .rg_we(is_wr_en),
    .rd_addr(rd_ad),
    .rg_re1(is_rd_en1),
    .rs1_addr(rs1_ad),
    .rg_re2(is_rd_en2),
    .rs2_addr(rs2_ad),
    
    // instruction field wiring
    .opCode(opCode),
    .funct3(funct3),
    .funct7(funct7),
    .immediateExtd(immediate_value)
  );

endmodule
