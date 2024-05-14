`timescale 1 ns / 1 ps


module ReadWriteMemory_tb;
  // parameter setting
  parameter START_ADDRESS  = 1024; // should be always multiple of four
  parameter STOP_ADDRESS    = 31 + START_ADDRESS;
  

  // input signals
  reg clk = 0;
  // write related signal
  reg [31:0]  wr_addr = 0;
  reg         wr_en = 0;
  reg [31:0]  wr_data = 0;
  reg [1:0]   wr_mode = 0;
  //read related signal
  reg [31:0]  rd_addr = 0;
  reg         rd_en = 0;
  wire [31:0] rd_data;
  reg [1:0]   rd_mode = 0; 


  // instantiate the ByteRAM module
  ByteRAM # (
    .START_ADDRESS(START_ADDRESS),
    .STOP_ADDRESS(STOP_ADDRESS)
  ) u0 (
    .clk(clk),
    // write related signals
    .wr_addr(wr_addr),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .wr_mode(wr_mode),
    // read related signals
    .rd_addr(rd_addr),
    .rd_en(rd_en),
    .rd_mode(rd_mode),
    .rd_data(rd_data)
  );
  
  localparam DURATION = 2 * 2048;
  // clock generation
  always #5 clk = ~clk; // toggle clock every 5 time units (i.e 5 ns, so here cycle length is 10 ns)
  
  // block to change the read and write mode
  integer ad;
  initial begin
    #5 rd_en = 1;
    #5 wr_en = 0;
    
    $monitor(" wr_data=%h, rd_data=%h", wr_data, rd_data);
    for (ad = START_ADDRESS; ad < STOP_ADDRESS; ad = ad+1) begin
      rd_addr = ad; // read byte by byte
      #10;
    end
    
    // write byte by byte
    rd_en = 0;
    wr_en = 1;
    wr_mode = 0;
    for (ad = START_ADDRESS; ad < STOP_ADDRESS; ad = ad+1) begin
      wr_addr = ad;
      wr_data[7:0] = $random;
      #10;
    end
    wr_data = 0;

    // read byte by byte
    rd_en = 1;
    wr_en = 0;
    rd_mode = 0;
    for (ad = START_ADDRESS; ad < STOP_ADDRESS; ad = ad+1) begin
      rd_addr = ad; // read byte by byte
      #10;
    end

    // write two byte
    rd_en=0;
    wr_en=1;
    wr_mode=1; // c style length index
    for (ad = START_ADDRESS; ad < STOP_ADDRESS; ad = ad+2) begin
      wr_addr = ad;
      wr_data[15:0] = $random;
      #10;
    end
    wr_data = 0;

    // read two byte
    rd_en=1;
    wr_en=0;
    rd_mode=1;
    for (ad = START_ADDRESS; ad < STOP_ADDRESS; ad = ad+2) begin
      rd_addr = ad;
      #10;
    end

    // write a word
    rd_en = 0;
    wr_en = 1;
    wr_mode = 2;
    for (ad = START_ADDRESS; ad < STOP_ADDRESS; ad = ad+4) begin
      wr_addr = ad;
      wr_data[31:0] = $random;
      #10;
    end
    wr_data = 0;

    // read a word
    rd_en=1;
    wr_en=0;
    rd_mode=2;
    for (ad = START_ADDRESS; ad < STOP_ADDRESS; ad = ad+4) begin
      rd_addr = ad;
      #10;
    end

  end

  // simulation record
  initial begin
    $dumpfile("ByteRAMaccess.vcd");
    $dumpvars(0, ReadWriteMemory_tb);
    #(DURATION)
    $display("Finished!");
    $finish;
  end

endmodule
