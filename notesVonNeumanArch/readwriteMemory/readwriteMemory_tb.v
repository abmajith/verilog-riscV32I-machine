`timescale 1 ns / 1 ps

module ReadWriteMemory_tb;
  // parameter setting
  parameter DATA_WIDTH = 32;
  parameter DATA_DEPTH = 16;

  // Inputs
  reg clk = 0;
  reg rd_en = 0;
  reg wr_en = 0;
  reg [($clog2(DATA_DEPTH)-1):0] address = 0;
  reg [DATA_WIDTH-1:0] write_data;
  // output
  wire [DATA_WIDTH-1:0] read_data;
	
  // instantiate read write data memory
  ReadWriteMemory #(
    .DATA_WIDTH(DATA_WIDTH),
    .DATA_DEPTH(DATA_DEPTH)
  ) uut (
    .clk(clk),
    .addr(address),
    .rd_en(rd_en),
    .wr_en(wr_en),
    .write_data(write_data),
    .read_data(read_data)
  );

  localparam DURATION = 1024;

  // clock generation
  always #5 clk = ~clk; // toggle clock every 5 time units (i.e 5 ns, so here cycle length is 10 ns)

  // block to change the read and write mode
  integer ad;
  initial begin
    #5 rd_en = 1;
    #5 wr_en = 0;
    // first read, see is it returning garbage or not
    for (ad = 0; ad < DATA_DEPTH; ad = ad+1) begin
      address = ad;
      #10;
      rd_en = 1;
      wr_en = 0;
    end

    rd_en = 0;
    wr_en = 1;
    // second just write
    for (ad = 0; ad < DATA_DEPTH; ad = ad+1) begin
      address = ad;
      write_data = $random;
      #10;
      rd_en = 0;
      wr_en = 1;
    end

    rd_en = 1;
    wr_en = 0;
    // now read and check its same sequence as writen 16 cycle ago
    for (ad = 0; ad < DATA_DEPTH; ad = ad+1) begin
      address = ad;
      #10;
      rd_en = 1;
      wr_en = 0;
    end
		
    // now simulate, what exactly happens when we do both read and write enable
    rd_en = 1;
    wr_en = 1;
    for (ad = 0; ad < DATA_DEPTH; ad = ad+1) begin
      address = ad;
      write_data = $random;
      #10;
      rd_en = 1;
      wr_en = 1;
    end
		
    rd_en = 1;
    wr_en = 0;
    // now read and check its same sequence as writen 16 cycle ago
    for (ad = 0; ad < DATA_DEPTH; ad = ad+1) begin
      address = ad;
      #10;
      rd_en = 1;
      wr_en = 0;
    end

    wr_en = 0;
    rd_en = 0;
  end
  // simulation record
  initial begin
    $dumpfile("ReadWriteMemory_tb.vcd");
    $dumpvars(0, ReadWriteMemory_tb);

    #(DURATION)

    $display("Finished!");
    $finish;
  end
endmodule
