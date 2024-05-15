`timescale 1 ns / 1 ps

module IV32IBranch_tb;
  // for timing analysis of this combinational logical branch circuit in simulation
  reg clk = 0;
  reg br_execute = 1;
  //operands
  reg [31:0] operandA = 0;
  reg [31:0] operandB = 0;
  // funct3 code
  reg [2:0] funct3 = 0;
  // output result of branching simple yes or no
  wire do_branch;

  // instantiate branch logic unit
  IV32IBranch uut (
    .br_execute(br_execute),
    .op_a(operandA),
    .op_b(operandB),
    .funct3(funct3),
    .do_branch(do_branch)
  );

  localparam DURATION = 256;
  // clock generation
  always #5 clk=~clk;
  
  initial begin
    $monitor($time, " do_branch=%b, operandA=%h, operandB=%h", do_branch, operandA, operandB);
    #30;
    operandA = 12;
    operandB = 12;
    $display("Equality test on A=%h,B=%h",operandA,operandB);
    funct3 = 3'b000; // equality

    #10;
    operandA = 11;
    operandB = 13;
    $display("Equality test on A=%h,B=%h",operandA,operandB);
    funct3 = 3'b000; // equality

    #10;
    operandA = 11;
    operandB = 13;
    $display("Not Equal test on A=%h,B=%h",operandA,operandB);
    funct3 = 3'b001; // not equal

    #10;
    operandA = 11;
    operandB = 11;
    $display("Not Equal test on A=%h,B=%h",operandA,operandB);
    funct3 = 3'b001; // not equal

    #10;
    operandA = 11;
    operandB = 10;
    $display("Less than test on A=%h,B=%h",operandA,operandB);
    funct3 = 3'b100; // less than

    #10;
    operandA = 7;
    operandB = 41;
    $display("Less than test on A=%h,B=%h",operandA,operandB);
    funct3 = 3'b100; // less than

    #10;
    operandA = 7;
    operandB = 41;
    $display("Greater than equal test on A=%h,B=%h",operandA,operandB);
    funct3 = 3'b101; // greater than equal

    #10;
    operandA = 42;
    operandB = 41;
    $display("Greater than equal test on A=%h,B=%h",operandA,operandB);
    funct3 = 3'b101; // greater than equal
    
    #10;
    operandA = 32'hffff_1234;
    operandB = 32'h0fff_1234;
    $display("Less than unsigned test on A=%h,B=%h",operandA,operandB);
    funct3 = 3'b110; // less than unsigned 

    #10;
    operandA = 32'h0fff_1234;
    operandB = 32'hffff_1234;
    $display("Less than unsigned test on A=%h,B=%h",operandA,operandB);
    funct3 = 3'b110; // less than unsigned 


    #10;
    operandA = 32'hffff_1234;
    operandB = 32'h0fff_1234;
    $display("Greater than equal unsigned test on A=%h,B=%h",operandA,operandB);
    funct3 = 3'b111; // greater than equal unsigned

    #10;
    operandA = 32'h0fff_1234;
    operandB = 32'hffff_1234;
    $display("Greater than equal unsigned test on A=%h,B=%h",operandA,operandB);
    funct3 = 3'b111; // greater than equal unsigned
    

    #10;
    operandA = 32'hffff_ffff;
    operandB = 32'hffff_ffff;
    $display("default test on A=%h,B=%h",operandA,operandB);
    funct3 = 3'b010; // default

    #10;
    operandA = 32'hffff_ffff;
    operandB = 32'hffff_ffff;
    $display("default test on A=%h,B=%h",operandA,operandB);
    funct3 = 3'b011; // default
  end
  // simulation record
  initial begin
    $dumpfile("branch_tb.vcd");
    $dumpvars(0, IV32IBranch_tb);
    #(DURATION)
    $display("Finished!");
    $finish;
  end
endmodule
