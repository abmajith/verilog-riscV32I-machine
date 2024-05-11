`timescale 1 ns / 1 ps

module IV32IALU_tb;
  
  reg clk = 0;
  //operands
  reg [31:0] operandA = 0;
  reg [31:0] operandB = 0;
  // funct3 code
  reg [2:0] funct3 = 0;
  reg       op_sign = 0;
  
  wire zero;
  wire negative;
  wire overflow;
  wire [31:0] out;

  // instantiate arithmetic logic unit 
  IV32IALU uut (
    .op_a(operandA),
    .op_b(operandB),
    .funct3(funct3),
    .op_sign(op_sign),
    .zero(zero),
    .negative(negative),
    .overflow(overflow),
    .result(out)
  );
  localparam DURATION = 256;
  // clock generation
  always #5 clk=~clk;
  
  initial begin
    $monitor($time, " out=%h, zero=%b, negative=%b, overflow=%b", out, zero, negative, overflow);
    #30;
    operandA = 12;
    operandB = 13;
    op_sign = 0;
    $display("Addition A=%h,B=%h",operandA,operandB);
    funct3 = 3'b000; // addition

    #10;
    operandA = 11;
    operandB = 13;
    op_sign = 1; // subtraction
    $display("Subtraction A=%h,B=%h",operandA,operandB);
    funct3 = 3'b000;

    #10;
    operandA = 32'h1000_0000;
    operandB = 32'h0000_0002;
    op_sign = 0;
    $display("Shift left operations A=%h,B=%h",operandA,operandB);
    funct3 = 3'b001; // shift left operations
    
    #10;
    operandA = -32'd18;
    operandB = 14;
    op_sign = 0;
    $display("Set less than A=%h,B=%h",operandA,operandB);
    funct3 = 3'b010; // less than operations

    #10;
    operandA = 18;
    operandB = 15;
    op_sign = 0;
    $display("Set less than unsigned numbers A=%h,B=%h",operandA,operandB);
    funct3 = 3'b011; // less than operations for unsigned numbers

    #10;
    operandA = 32'hffff_0000;
    operandB = 32'h0000_ffff;
    op_sign = 0;
    $display("xor operations A=%h,B=%h",operandA,operandB);
    funct3 = 3'b100; // xor operations

    #10;
    operandA = 32'hffff0001;
    operandB = 2;
    op_sign = 1; // signed shift right operations
    $display("shift right arithmetic A=%h,B=%h, ans=%h",operandA,operandB, $signed(operandA) >>> operandB[4:0]);
    funct3 = 3'b101;

    #10;
    operandA = 32'h1000_0000;
    operandB = 7;
    op_sign = 0; // shift right operations
    $display("shift right logical operations A=%h,B=%h",operandA,operandB);
    funct3 = 3'b101;

    #10;
    operandA = 32'h1000_0000;
    operandB = 32'hE000_0000;
    op_sign = 0;
    $display("OR A=%h,B=%h",operandA,operandB);
    funct3 = 3'b110; // or operations

    #10;
    operandA = 32'h1000_0000;
    operandB = 32'hE000_0000;
    op_sign = 0;
    $display("And A=%h,B=%h",operandA,operandB);
    funct3 = 3'b111; // and operations
  
    #10;
  end

  // simulation record
  initial begin
    $dumpfile("alu_tb.vcd");
    $dumpvars(0, IV32IALU_tb);
    #(DURATION)
    $display("Finished!");
    $finish;
  end
endmodule
