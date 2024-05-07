`timescale 1 ns / 1 ps

module InstructionMemory_tb;
  // parameter setting
  parameter INST_WIDTH = 32;
  parameter INST_DEPTH = 16;

  // Inputs
  reg clk   = 0;
  reg rd_en = 0;
  reg [($clog2(INST_DEPTH)-1):0] address = 0;

  // Outputs
  wire [INST_WIDTH-1:0] instruction;

  // instantiate the read only memory instruction module
  InstructionMemory #(
    .INST_WIDTH(INST_WIDTH),
    .INST_DEPTH(INST_DEPTH)
  ) uut (
    .clk,
    .rd_addr(address),
    .rd_en(rd_en),
    .instruction(instruction)
  );

  localparam DURATION = 1000;

  // clock generation
  always #5 clk = ~clk; // toggle clock every 5 time units (i.e 5 ns, so here cycle length is 10 ns)

  // Test sequence
  integer addr;
  initial begin
    #10 rd_en = 0;
    #10 rd_en = 1;
    for (addr = 0; addr < INST_DEPTH+2; addr = addr+1) begin
      address = addr;
      rd_en = 1;
      #10 rd_en = 0;
    end
  end

  // simulation record
  initial begin
    $dumpfile("InstructionMemory_tb.vcd");
    $dumpvars(0, InstructionMemory_tb);

     #(DURATION)

    $display("Finished!");
    $finish;
  end
endmodule
