module processor(
  // clock signal
  input clk,
  // reset signal active high
  input rst);
  
  // program counter act as instruction address
  reg [31:0] PC;
  // to load the next instruction address
  reg [31:0] nextPC;

  // for holding current instruction and its validity
  wire [31:0] inst;
  wire        isValidInst;

  // couple of wires to hold current instruction fields signals
  wire [6:0]  opCode;
  wire [2:0]  funct3;
  wire [6:0]  funct7;
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
  
  // to set the write back to the register banks
  reg en_wr_reg = 1'b0;  // default
  // couple of wires to signal 32-bit value
  wire [31:0] rs1_value;
  wire [31:0] rs2_value;
  wire [31:0] rd_value;

  //registerfile instance
  registerFile # (
      .REG_DEPTH(32),
      .REG_WIDTH(32),
      .RADDR_WIDTH(5)
    )  regBank (
      // clock and reset signals
      .clk(clk),
      .rst(rst),
      // writing the result mode?
      .we(en_wr_reg),
      // source and destination register address
      .rs1_addr(rs1_ad),
      .rs2_addr(rs2_ad),
      .rd_addr(rd_ad),
      .rd_value(rd_value),
      .rs1_value(rs1_value),
      .rs2_value(rs2_value)
    );
  

  // for making the appropriate operands for the instruction
  reg [31:0] op_a;
  reg [31:0] op_b;
  
  // couples of signals and registers for alu unit
  wire        alu_zero;
  wire        alu_negative;
  wire        alu_overflow;
  wire [31:0] alu_result;
  wire op_sign = inst[30];
  wire alu_execute = (is_alu_reg || is_alu_imm) ? 1'b1 : 1'b0;

  // alu instance
  IV32IALU alu (
        // control signals
        .alu_execute(alu_execute),
        // operands and function code
        .op_a(op_a),
        .op_b(op_b),
        .funct3(funct3),
        .op_sign(op_sign),
        // alu output with some flags
        .zero(alu_zero),
        .negative(alu_negative),
        .overflow(alu_overflow),
        // result of alu
        .result(alu_result)
    );
  
  
  wire branch_result;
  // branch unit
  IV32IBranch brUnit (
      // control signals
      .br_execute(is_branch),
      // operands
      .op_a(op_a),
      .op_b(op_b),
      // type of branch
      .funct3(funct3),
      // result of branch
      .do_branch(branch_result)
    );
  
  /* if lui, then immediate value is the result, 
    if auipc, the adding immediate value with PC is the operation result */
  wire [31:0] lui_auipc_result = (is_lui) ? immediate_value :
                                    (is_auipc) ? (immediate_value + PC) :
                                        32'b0;
  
  /* if jal or jalr, the instruction result is same*/

  wire [31:0] jal_jalr_result = (is_jal || is_jalr) ? PC + 4 : 32'b0;
  
  /*for system instruction type decided by is_system, we will run the 
    asembly program in a loop. i.e initialize PC to start address of assembly code */
  /*we are not doing fence instruction, */
  

  /* compute the load_mem_addr and store_mem_addr based on the instruction type */
  wire [31:0] load_mem_addr  = (is_load)  ? op_a + immediate_value : 32'b0;
  wire [31:0] store_mem_addr = (is_store) ? op_b + immediate_value : 32'b0;
  /* we do need the mode, i.e half word or full word or a byte,
    it is decided by the funct3 operations*/
  wire [1:0] mode_load  = (is_load)  ? funct3[1:0] : 2'b0;
  wire [1:0] mode_store = (is_store) ? funct3[1:0] : 2'b0;
  // loaded data by load instruction
  wire [31:0] load_read_data;

  // signal for enabling the RAM write and read data
  reg wr_en_RAM = 0; // default dont write
  reg rd_en_RAM = 0; // default dont read anything

  // instance for read/write data memory
  ByteRAM # (
    .START_ADDRESS(1024),
    .STOP_ADDRESS(2047) // a block of 1024 bytes for read and write data
  ) rwDataMem (
    // clock signals
    .clk(clk),
    // various signals for write action
    .wr_addr(store_mem_addr),
    .wr_en(wr_en_RAM),
    .wr_data(op_a),
    .wr_mode(mode_store),
    // various signals for read action
    .rd_addr(load_mem_addr),
    .rd_en(rd_en_RAM),
    .rd_mode(mode_load),
    .rd_data(load_read_data)
  );
  
endmodule
