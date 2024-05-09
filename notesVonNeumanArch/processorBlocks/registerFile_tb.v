`timescale 1 ns / 1 ps

module RegisterFile_TB;
  parameter REG_DEPTH = 32;
  parameter REG_WIDTH = 32;
  parameter RADDR_WIDTH = 5; 

  // inputs
  reg clk = 0;
  reg rst = 1;
  reg we = 0;
  reg [RADDR_WIDTH-1:0] rs1_addr = 0;
  reg [RADDR_WIDTH-1:0] rs2_addr = 0;
  reg [RADDR_WIDTH-1:0] rd_addr  = 0;
  reg [REG_WIDTH-1:0]   rd_value = 0;

  // outputs
  wire [REG_WIDTH-1:0]   rs1_value;
  wire [REG_WIDTH-1:0]   rs2_value;
  
  registerFile # (
                .REG_DEPTH(REG_DEPTH),
                .REG_WIDTH(REG_WIDTH),
                .RADDR_WIDTH(RADDR_WIDTH)
               )
              uo (
              .clk(clk),
              .rst(rst),
              .we(we),
              .rs1_addr(rs1_addr),
              .rs2_addr(rs2_addr),
              .rd_addr(rd_addr),
              .rd_value(rd_value),
              .rs1_value(rs1_value),
              .rs2_value(rs2_value)
              );
  // Clock generation
  always #5 clk = ~clk;
  localparam DURATION = 1024;
  // stimuls
  initial 
    $monitor($time, " rd_addr=%d, rs1_addr=%d,rs2_addr=%d,rd_value=%d, rs1_value=%d, rs2_value=%d", rd_addr, rs1_addr, rs2_addr, rd_value, rs1_value, rs2_value);
  initial begin
    // Reset
    rst = 1;
    #10 rst = 0;

    // write to register 1
    we = 1;
    for (integer ad = 0; ad < 32; ad = ad + 1) begin
      rd_addr = ad;
      rd_value = $random & 32'hffff_ffff;
      #10;
    end
    #5 we = 0;

    for (integer ad = 0; ad < 32; ad = ad + 1) begin
      rd_addr = 5'b0;
      rs1_addr = ad;
      rs2_addr = 31 - ad;
      #10;
    end
  end
  // simulation record
  initial begin
    $dumpfile("register_tb.vcd");
    $dumpvars(0, RegisterFile_TB);
    #(DURATION)
    $display("Finished!");
    $finish;
  end

endmodule
