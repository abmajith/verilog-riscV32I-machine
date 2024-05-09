module decode (
  // instruction to decode
  input [31:0] instruction,

  // couple of register address to read and write
  output       rg_we, // register write enable
  output [5:0] rd_addr,
  output       rg_re1 // use rs1_addr enable
  output [5:0] rs1_addr,
  output       rg_re2, // use rs2_addr enable
  output [5:0] rs2_addr,

  // opcode 
  output [6:0] opCode,
  // func3, funct7
  output [3:0] funct3,
  output [6:0] funct7,
  output [31:0] immediateExtd,
);

  // internal signals

  // if inst is *I-type* instruction
  wire [31:0] Iimm = { {21{instruction[31]}}, instruction[30:20]};
  // if inst is *S-type* instruction
  wire [31:0] Simm = { {21{instruction[31]}}, instruction[30:25], instruction[11:7]};
  // if inst is *B-type* instruction
  wire [31:0] Bimm = { {20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
  // if inst is *U-type* instruction
  wire [31:0] Uimm = { instruction[31:12], {12{1'b0}}};
  // if inst is *J-type* instruction
  wire [31:0] Jimm = { {12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
  

  // consistency in the placement of other fields in the instruction, makes easier to extract the details as 
  // extracting opcode, funct3, funct7
  opCode = {instruction[6:0]};
  funct3 = {instruction[14:12]};
  funct7 = {instruction[31:25]};
  // extracting register address fields 
  rd_addr  = {instruction[11:7]};
  rs1_addr = {instruction[19:15]};
  rs2_addr = {instruction[24:20]};
  

  // extracting the immediate field into extended immediate format as disuccused in the documents
  // also set up the enable for register address rd, rs1, rs2.
  always @ (*) begin
    case (instruction[6:0])
      7'b0110111: begin // LUI U-type instruction
        immediateExtd = Uimm;
        rg_we = 1'b1;
        rg_re1 = 1'b0;
        rg_re2 = 1'b0;
      end

      7'b0010111: begin // AUIPC U-type instruction
        immediateExtd = Uimm;
        rg_we = 1'b1;
        rg_re1 = 1'b0;
        rg_re2 = 1'b0;
      end

      7'b1101111: begin // JAL J-type instruction
        immediateExtd = Jimm;
        rg_we = 1'b1;
        rg_re1 = 1'b0;
        rg_re2 = 1'b0;
      end

      7'b1100111: begin // JALR I-type instruction
        immediateExtd = Iimm;
        rg_we = 1'b1;
        rg_re1 = 1'b1;
        rg_re2 = 1'b0;
      end

      7'b1100011: begin // branch B-type instruction
        immediateExtd = Bimm;
        rg_we = 1'b0;
        rg_re1 = 1'b1;
        rg_re2 = 1'b1;
      end

      7'b0000011: begin // load I-type instruction
        immediateExtd = Iimm;
        rg_we = 1'b1;
        rg_re1 = 1'b1;
        rg_re2 = 1'b0;
      end

      7'b0100011: begin // store S-type instruction
        immediateExtd = Simm;
        rg_we = 1'b0;
        rg_re1 = 1'b1;
        rg_re2 = 1'b1;
      end

      7'b0010011: begin // immediage arithmetic operations type
        immediateExtd = Iimm;
        rg_we = 1'b1;
        rg_re1 = 1'b1;
        rg_re2 = 1'b0;
      end

      7'b0110011: begin // arithemtic operation on register type
        immediateExtd = 32'b0;
        rg_we = 1'b1;
        rg_re1 = 1'b1;
        rg_re2 = 1'b1;
      end

      7'b0001111: begin // fench type, not implemented here or documented
        immediateExtd = 32'b0;
        rg_we = 1'b0;
        rg_re1 = 1'b0;
        rg_re2 = 1'b0;
      end
      7'b1110011: begin // system type, not implemented here or doucmented
        immediateExtd = 32'b0;
        rg_we = 1'b0;
        rg_re1 = 1'b0;
        rg_re2 = 1'b0;
      end
      
      default: begin // default execution
        immediateExtd = 32'b0;
        rg_we = 1'b0;
        rg_re1 = 1'b0;
        rg_re2 = 1'b0;
      end

    endcase // for case

  end // for always

endmodule
