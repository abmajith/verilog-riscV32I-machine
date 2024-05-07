`timescale 1 ns / 1 ps

module GPIO_tb;
  // Parameters
  localparam NUM_GPIO_SETS = 4;
  localparam GPIO_WIDTH = 8;

  //signals
  reg clk = 0;
  reg rst = 0;
  reg [$clog2(NUM_GPIO_SETS):0] addr;
  reg [GPIO_WIDTH-1:0] wr_data;
  wire [GPIO_WIDTH-1:0] rd_data;

  // instance of GPIO pins
  GPIO #( 
    .NUM_GPIO_SETS(NUM_GPIO_SETS),
    .GPIO_WIDTH(GPIO_WIDTH)
  ) u0 (
    .clk(clk),
    .rst(rst),
    .addr(addr),
    .wr_data(wr_data),
    .rd_data(rd_data)
  );

  localparam DURATION = 256;

  // clock generation
  always #5 clk = ~clk; // toggle clock every 5 time units (i.e 5 ns, so here cycle length is 10 ns)
	
  // Reset generation
  initial begin
    rst = 1;
    #10 rst = 0;
  end
  // block to change the read and write mode
  integer ad;
  initial begin
    // set all the GPIO pins are write in status
    #20;
    for (ad = 0; ad < 8; ad = ad + 2) begin
      addr = ad;
      wr_data = {8{1'b1}};
      #10;
    end
    // now assign some data to the writable GPIO pins
    for (ad = 1; ad < 2 * NUM_GPIO_SETS; ad = ad + 2) begin
      addr = ad;
      wr_data = $random;
      #10;
    end

    wr_data = {8{1'b0}};
    // now set all the GPIO pins are read in status
    for (ad = 0; ad < 8; ad = ad + 2) begin
      addr = ad;
      #10;
    end
    #20
    // now read the readable GPIO pins
    for (ad = 1; ad < 8; ad = ad + 2) begin
      addr = ad;
      #10;
    end
    #10
    // now read the readable GPIO pins
    for (ad = 1; ad < 8; ad = ad + 2) begin
      addr = ad;
      #10;
    end
  end
	

  // simulation record
  initial begin
    $dumpfile("GPIO_tb.vcd");
    $dumpvars(0, GPIO_tb);

    #(DURATION)

    $display("Finished!");
    $finish;
  end

endmodule
