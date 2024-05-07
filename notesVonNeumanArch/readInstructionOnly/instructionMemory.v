module InstructionMemory 
  # ( 
  // instruction encoding width
  parameter INST_WIDTH = 32, 
  // number of instructions stored locally
  parameter INST_DEPTH = 1024
  ) (
  // clock signal
  input wire clk,
  // address to read the given instruction 
  input wire [($clog2(INST_DEPTH)-1):0] rd_addr, 
  // enable reading the instruction
  input wire rd_en,
  // loading the instruction from the address
  output reg [INST_WIDTH-1:0] instruction
  );

  reg [INST_WIDTH-1:0] memory [0:INST_DEPTH-1];
	
  initial begin
    $readmemh("instruction_init.hex", memory);
  end
  // read triggered by positve edge of clock and readEnable signal
  always @ (posedge clk) begin 
    if (rd_en) begin
      instruction <= (rd_addr < INST_DEPTH) ? memory[rd_addr] : 0;
    end
  end
endmodule
