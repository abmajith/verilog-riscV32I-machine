`timescale 1 ns / 1 ps

module instructionDecoderTB;
  reg clk = 0;

  reg  [31:0] instruction;
  wire wr_en;
  wire rd_en1;
  wire rd_en2;
  wire [4:0] rd_addr;
  wire [4:0] rs1_addr;
  wire [4:0] rs2_addr;
  

  wire [6:0] opcode;
  wire [2:0] funct3;
  wire [6:0] funct7;
  wire [31:0] immed;

  decode u0(
        .instruction(instruction),
        .rg_we(wr_en),
        .rd_addr(rd_addr),
        .rg_re1(rd_en1),
        .rs1_addr(rs1_addr),
        .rg_re2(rd_en2),
        .rs2_addr(rs2_addr),
        .opCode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .immediateExtd(immed)
  );

  // clock generation
  always #5 clk = ~clk;
  localparam DURATION = 1024;

  initial
    $monitor($time, " wr_en=%b,rd_addr=%d, rd_en1=%b,rs1_addr=%d, rd_en2=%b,rs2_addr=%d,opCode=%b,funct3=%b,funct7=%b,immed=%h", 
                    wr_en, rd_addr, rd_en1, rs1_addr, rd_en2, rs2_addr, opcode, funct3, funct7, immed);
  initial begin

    // R-type instruction
    $display("R-type instruction");
    #5 instruction = 32'b0000000_00000_00000_000_00001_0110011;
    #10;

    // I-type instruction arithmetic
    $display("I-type instruction arithmetic");
    #5 instruction = 32'b000000000001_00001_000_00001_0010011;
    #10;

    // load instruction I-type
    $display("I-type instruction load");
    #5 instruction = 32'b000000000000_00001_010_00010_0000011;
    #10;

    // store instruction S-type
    $display("S-type instruction store");
    #5 instruction = 32'b000000_00001_00010_010_00000_0100011;
    #10;

    // system instruction
    $display("system instruction");
    #5 instruction = 32'b000000000001_00000_000_00000_1110011;
    #10;

    // fench instruction
    $display("Fence instruction");
    #5 instruction = 32'b0000000000000000000000000_1110011;
    #10;

    // branch instruction
    $display("branch instruction B-type");
    #5 instruction = 32'b0000000_00000_00001_000_00000_1100011;
    #10;

    // JALR instruction
    $display("JALR instruction I-type");
    #5 instruction = 32'b00000000000_00001_000_00000_1100111;
    #10;

    //  JAL instruction
    $display("JAL instruction J-type");
    #5 instruction = 32'b01010101010101010101_00000_1101111;
    #10;

    // AUIPC U-type
    $display("AUIPC U-type instruction");
    #5 instruction = 32'b00000000000000000001_00000_0010111;
    #10;
    // LUI J-type
    $display("LUI U-type instruction");
    #5 instruction = 32'b00000000000000000010_00000_0110111;
    #10;

  end
  
  initial begin
    $dumpfile("decoder_tb.vcd");
    $dumpvars(0, instructionDecoderTB);
    #(DURATION)
    $display("Finished!");
    $finish;
  end

endmodule
