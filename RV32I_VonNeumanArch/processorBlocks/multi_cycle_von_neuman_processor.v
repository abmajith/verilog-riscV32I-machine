
`include "alignedMemory.v"
`include "registerFile.v"
`include "alu_block.v"
`include "branch_block.v"
`include "instructionDecoder.v"

module processor (
  // clock signal
  input clk,
  // reset signal active high
  input rst
);
  
  // program counter, acts as instruction address
  reg [31:0] PC;
  // to load the next instruction address
  reg [31:0] nextPC = 0;

  // for holding current instruction and its validity
  wire [31:0] inst;
  wire        isValidInst;

  // instruction fields signals
  wire [6:0]  opCode;
  wire [2:0]  funct3;
  wire [6:0]  funct7;
  wire [31:0] immediate_value;
  
  /* register source and destination address and 
    its mode signals for the current instruction */
  wire [4:0] rs1_ad;
  wire [4:0] rs2_ad;
  wire [4:0] rd_ad;
  
  /* additional control signals on how to treat two source registers 
    and one destination registers */
  wire is_wr_en; // destination register write
  wire is_rd_en1; // first register source read
  wire is_rd_en2; // second register source read

  // based on opcode, hold instruction type by assigning the following wires
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
    
    // instruction fields wiring
    .opCode(opCode),
    .funct3(funct3),
    .funct7(funct7),
    .immediateExtd(immediate_value)
  );
  

  // couple of wires to signal 32-bit register values
  wire [31:0] rs1_value;
  wire [31:0] rs2_value;
  wire [31:0] rd_value;

  /*registerfile instance, 
    in this instance, we always read, it wont affect us, but
    we trigger write enable to safely write the result into our register */
  
  // to enable write back data to the register banks
  reg en_wr_reg = 1'b0;

  registerFile # (
      .REG_DEPTH(32),
      .REG_WIDTH(32),
      .RADDR_WIDTH(5)
    )  regBank (
      // clock and reset signals
      .clk(clk),
      .rst(rst),

      // write enable mode set up
      .we(en_wr_reg),

      // source and destination register address
      .rs1_addr(rs1_ad),
      .rs2_addr(rs2_ad),
      .rd_addr(rd_ad),
      .rd_value(rd_value),
      .rs1_value(rs1_value),
      .rs2_value(rs2_value)
    );
  

  /* to set up the two input operands (for any instruction there are at most 
    two operands, and one immediate field)*/
  reg [31:0] op_a;
  reg [31:0] op_b;
  


  // couples of signals and registers for alu unit
  wire        alu_zero;
  wire        alu_negative;
  wire        alu_overflow;
  wire [31:0] alu_result;
  wire op_sign = inst[30];
  wire alu_execute = (is_alu_reg || is_alu_imm) ? 1'b1 : 1'b0;

  // alu instance, note this is pure combinational logical circuit
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
  
  // branch result
  wire branch_result;
  // branch unit instance, also a combinational logical circuit
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
  
  /* combinational logical circuit for performing lui,auipc instructions */
  wire [31:0] lui_auipc_result = (is_lui) ? immediate_value :
                                    (is_auipc) ? (immediate_value + PC) :
                                        32'b0;
  
  /* if jal or jalr, the instruction result is same, 
    but differs in how it moves to next instruction*/
  /* combinational logical circuit for performing jal,jalr instructions */
  wire [31:0] jal_jalr_result = (is_jal || is_jalr) ? PC + 4 : 32'b0;
  
  /*for system instruction ebreak, we will run the 
    asembly program in a loop. i.e initialize PC to start address of assembly code,
    this ebreak operations are used for debugging ports and links, we are not designed 
    or added any debugging ports, so lets do this way */

  /*we are not doing fence instruction, 
    fence instruction makes sense in multicore, multi-tenant processor design*/
  

  /* combinational logical circuit for computing load_mem_addr, and store_mem_addr */
  wire [31:0] load_mem_addr  = (is_load)  ? op_a + immediate_value : 32'b0;
  wire [31:0] store_mem_addr = (is_store) ? op_b + immediate_value : 32'b0;

  /* we do need the mode, i.e half word or full word or a byte,
    it is decided by the funct3 signals*/
  wire [1:0] mode_load  = (is_load)  ? funct3[1:0] : 2'b0;
  wire [1:0] mode_store = (is_store) ? funct3[1:0] : 2'b0;

  // loaded data from RAM
  wire [31:0] load_read_data;

  // to enable write back data to read/write memory ram
  reg wr_en_RAM = 0; // default don't write

  // to enable read data from read/write memory ram
  reg rd_en_RAM = 0; // default don't read

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
  

  
  // rd value is assigned based on the insruction type
  assign rd_value = (is_alu_reg || is_alu_imm) ? alu_result :
                      (is_jal || is_jalr) ? jal_jalr_result :
                        (is_lui || is_auipc) ? lui_auipc_result :
                          (is_load)  ? load_read_data : 32'b0;

  

  // Internal state machine
  parameter FETCH_DECODE = 2'b00;
  parameter EXECUTE      = 2'b01;
  parameter WRITEBACK    = 2'b10;
  
  // Internal signals
  reg [1:0] state;
  reg [1:0] next_state;

  // state machine transition actions
  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      // setting up the proper initial state
      state      <= FETCH_DECODE;
      next_state <= FETCH_DECODE;
      
      // setting up the program counter
      PC     <= 0;
      nextPC <= 0;

    end else begin
      // transition from one state to next state
      state <= next_state;
      PC    <= nextPC;
    end
  end
  

  /* nextPC should change only at the end of 3rd cycle
      i.e at write back, not any time before */
  // a separate block to update the nextPC as follow

  always @ (negedge clk) begin
    /* normally next pc will be updated by adding 4 and pc, 
      but branch and jump instruction have other ideas! */

    /* in unconditional jump (jal, jalr), 
      the rs1_value, and immediate_value extracted 
      at the fetch_decode state itself,
      so it has some reliability */ 

    /* in branch i.e conditional jump,
       branch_result should be ready at negative edge at the writeback state,
       otherwise it creates synchronization mismatch problem in the hardware.

       branch_result computed at execute cycle, if our hardware propagation dealy is 
       not too much, then it is safe, otherwise we have to reduce the clock frequency! */

    if (state == WRITEBACK) begin

      if (is_jal) begin // jump and link
        nextPC <= PC + immediate_value; 
      end else if (is_jalr) begin // jump and link register
        nextPC <= rs1_value + immediate_value; /*Risc-V naming convention is at supreme!*/
     
      end else if (is_branch && branch_result) begin // conditional jump, branching!
        nextPC <= PC + immediate_value;

      end else begin // sequence instruction execution
        nextPC <= PC + 4; // normal update
      end
    end
  end

  // separate block of controller to enable write/read operations

  /* initiating the write back enable signal 
    prior to write back state, 

    write back to ram or register usually happens at positive edge rise,
    even when we enable write back signal in the middle of  execution cycle, 
    write back the intended data starts only  
    at the begining of writeback state! */

  /* also safely disable write back 
      in the middle of write back state */
  
  always @ (negedge clk) begin
    // setting the write back enable signal
    if (state == EXECUTE) begin
      if (is_alu_reg || is_alu_imm || is_lui || is_auipc || is_jal || is_jalr) begin
        en_wr_reg = 1;
      end else if (is_store) begin
        wr_en_RAM = 1;
      end
    end
    
    // disable the write back signal prior to new instruction fetching
    if (state == WRITEBACK) begin
      en_wr_reg <= 0;
      wr_en_RAM <= 0;
    end

  end


  always @ (*) begin
    
    case (state)
      FETCH_DECODE: begin
        // for one full cycle, state stay here, 
        // combinational cirucit performs fetch and decode the instruction
        next_state <= EXECUTE;
        en_wr_reg <= 0;
        wr_en_RAM <= 0;
        rd_en_RAM <= 0;
      end
      
      EXECUTE: begin
        // we don't care two operands for lui, auipc and jump type instruction
        // for these instruction, we care only on rd_value

        op_a <= rs1_value;
        op_b <= (is_alu_reg || is_store || is_branch) ? rs2_value : 
                  (is_alu_imm) ? immediate_value : 
                    32'b0;

        /* for load we don't need second operand, 
          but we have to set up the enable read command to read them properly */
        /* reading data from memory is not synchrnoized with clock, but rather a combinational circuit
          with some propagation dealy it will load the result on load_read_data */
        rd_en_RAM = (is_load) ? 1'b1 : 1'b0;
        
       // the result like following are generated using combinational circuit in this state
       /* alu_result (32-bits), has to write back to rd_ad
          branch_result (1-bit),
          lui_auipc_result (32-bits), has to write back to rd_ad
          jal_jalr_result (32-bits), has to write back to rd_ad
          load_mem_addr (32-bits),
          store_mem_addr(32-bits),
          load_read_data(32-bits),   has to write back to rd_ad
       */
       next_state <=  WRITEBACK;
      end

       WRITEBACK: begin
        
        next_state <= FETCH_DECODE;
       end
    endcase // case
  end // always 
endmodule
