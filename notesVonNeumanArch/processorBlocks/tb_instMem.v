`timescale 1 ns / 1 ps


module InstructionMemory_tb;
  // parameter setting
  parameter START_ADDRESS  = 16; // should be always multiple of four
  parameter STOP_ADDRESS    = 47 + START_ADDRESS;
  

  // input signals
  reg clk = 0;
  reg [31:0] addr;
  // output signals
  wire [31:0] instruction;
  wire isValid;

  // instantiate the read only memory instruction module
  ByteAlignInstructionMemory # (
    .START_ADDRESS(START_ADDRESS),
    .STOP_ADDRESS(STOP_ADDRESS)
  ) u0 (
    .clk(clk),
    .iaddr(addr),
    .instruction(instruction),
    .isValid(isValid)
  );
  
  localparam DURATION = 1024;
  // clock generation
  always #5 clk = ~clk; // toggle clock every 5 time units (i.e 5 ns, so here cycle length is 10 ns)
  

   // Test sequence
  integer address;
  initial begin
    $monitor("addr=%d, isValid=%b instruction=%h",addr,isValid,instruction);
    for (address = START_ADDRESS; address < STOP_ADDRESS; address = address+4) begin
      addr = address;
      #10;
    end
  end

  // simulation record
  initial begin
    $dumpfile("InstructionAlignedMemoryAccess.vcd");
    $dumpvars(0, InstructionMemory_tb);
    #(DURATION)
    $display("Finished!");
    $finish;
  end

endmodule
