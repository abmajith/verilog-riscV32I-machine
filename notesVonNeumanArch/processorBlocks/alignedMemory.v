module ByteAlignInstructionMemory 
   # ( 
    // parameter to set memory within this region, stop address is excluded
    parameter START_ADDRESS   = 0, // should be mulitple of 4
    parameter STOP_ADDRESS    = 1023
   ) (
   // clock signal
   input clk,
   // for our 32-bit instruction address and instruction (data)
   input  [31:0] iaddr,
   output [31:0] instruction,
   output        isValid // to inform the instruction is aligned and within memory region
   );

  reg [7:0] mem [START_ADDRESS:STOP_ADDRESS];
  
  initial begin
    $readmemh("instruction_init.hex", mem);
  end
  
  assign isValid = ( iaddr >= START_ADDRESS && iaddr <= STOP_ADDRESS) ? 1'b1 : 1'b0;
  assign instruction = {{mem[{iaddr[31:2],2'b11}]}, {mem[{iaddr[31:2],2'b10}]}, {mem[{iaddr[31:2],2'b01}]}, {mem[{iaddr[31:2],2'b00}]} };
endmodule



module ByteRAM
  # (
    // parameter to set memory withing this region, stop address is excluded
    parameter START_ADDRESS   = 0,
    parameter STOP_ADDRESS    = 1023
  ) (
  // clock signal
  input clk,
  // write address with enable signal, and number of bytes
  input [31:0] wr_addr,
  input        wr_en,
  input [31:0] wr_data,
  input [1:0]  by_wlen, // byte write len

  // read address with enable signal, and number of bytes
  input [31:0] rd_addr,
  input        rd_en,
  input [1:0]  by_rlen,
  output [31:0] rd_data
  );

  reg [7:0] mem [START_ADDRESS:STOP_ADDRESS];

  always @ (posedge clk) begin
    if (wr_en) begin
      // there is atleast one byte to write
      mem[wr_addr+0] <= wr_data[7:0];
      mem[wr_addr+1] <= (|by_wlen)   ? wr_data[15:8]  : mem[wr_addr+1];
      mem[wr_addr+2] <= (by_wlen[1]) ? wr_data[23:16] : mem[wr_addr+2];
      mem[wr_addr+3] <= (&by_wlen)   ? wr_data[31:24] : mem[wr_addr+3];
      // note here this block is writing without alignment constraints
      // now we could realize why reading consecutive memory is faster than
      // reading byte here and there in c program
    end
  end
  assign rd_data[7:0]   = (rd_en)               ? {mem[rd_addr+0]} : 8'b0;
  assign rd_data[15:8]  = (rd_en && |by_rlen)   ? {mem[rd_addr+1]} : 8'b0;
  assign rd_data[23:16] = (rd_en && by_rlen[1]) ? {mem[rd_addr+2]} : 8'b0;
  assign rd_data[31:24] = (rd_en && &by_rlen)   ? {mem[rd_addr+3]} : 8'b0;

  // right now there is no check for valid memory area, it could be added by adding two more signals in the port list
  // will keep it simple now, later will add depends on the need!
endmodule



