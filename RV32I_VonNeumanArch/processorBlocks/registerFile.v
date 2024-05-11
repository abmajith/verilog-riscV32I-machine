module registerFile
  # (
    parameter REG_DEPTH = 32,
    parameter REG_WIDTH = 32,
    parameter RADDR_WIDTH = 5
  )(
  // inputs
  input clk,
  input rst,
  input we, // write enable
  input [RADDR_WIDTH-1:0] rs1_addr,
  input [RADDR_WIDTH-1:0] rs2_addr,
  input [RADDR_WIDTH-1:0] rd_addr,

  input [REG_WIDTH-1:0]   rd_value, 

  output [REG_WIDTH-1:0]  rs1_value, // this are set in blocking mode
  output [REG_WIDTH-1:0]  rs2_value
  );

  reg [REG_WIDTH-1:0] bank [REG_DEPTH-1:0];
  
  //reset logic
  always @ (posedge clk or posedge rst) begin
    if (rst) begin
      for (integer i = 0; i < REG_DEPTH; i = i + 1) begin
        bank[i] <= 0;
      end
    end
  end

  // write enable logic
  always @(posedge clk or posedge rst) begin
    if (we && (~rst)) begin
      if ( (0 < rd_addr) && (rd_addr < REG_DEPTH) ) begin
        bank[rd_addr] <= rd_value;
      end
    end
  end

  // Read assignment statement
  assign rs1_value = (~rst && |rs1_addr) ? bank[rs1_addr] : 0;
  assign rs2_value = (~rst && |rs2_addr) ? bank[rs2_addr] : 0;
endmodule
