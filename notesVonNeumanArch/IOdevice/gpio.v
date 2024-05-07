module GPIO # (
  // parameter for setting number of sets of 8-pin parallel port
  parameter NUM_GPIO_SETS = 4,
  parameter GPIO_WIDTH    = 8
) (
  // clock signal
  input wire clk,
  // reset a parallel port
  input wire rst,
  // address space for parallel ports
  input wire [$clog2(NUM_GPIO_SETS):0] addr,
  // enabling the status of the GPIO pin status and write/read data
  input wire [GPIO_WIDTH-1:0] wr_data,
  // data to read from the parallel port
  output reg [GPIO_WIDTH-1:0] rd_data
);
  // to store the data signal of all GPIO's
  reg [GPIO_WIDTH-1:0] gpio_status_data [0:(2*NUM_GPIO_SETS)-1];  
	
  // gpio_status_data[0,2,4,..] for GPIO pins read/write status
  // gpio_status_data[1,3,5,..] for actual GPIO pins data

  // initialize the data
  initial begin
    for (integer i = 0; i < 2*NUM_GPIO_SETS; i=i+1) begin
      gpio_status_data[i] = 0;
    end
  end
	
  // reset the mode
  always @ (posedge clk) begin
    if (rst) begin
      gpio_status_data[addr] <= 0;
    end
  end

  // setting the enable status (only write possible) of the GPIO pins
  always @ (posedge clk) begin
    if (~rst && !addr[0]) begin
      gpio_status_data[addr] <= wr_data;
    end
  end

  // write data on the write enabled pins, dont disturb the read pin's data
  always @ (posedge clk) begin
    if (~rst && addr[0]) begin // dealing with data register
      gpio_status_data[addr] <= (( gpio_status_data[addr-1]  & wr_data) 
                                  | ( ~(gpio_status_data[addr-1]) & gpio_status_data[addr] ));
    end
  end

  // Memory mapped I/O, reading
  always @ (posedge clk) begin
    if (~rst && addr[0]) begin // do reading
      // if a pin is write mode, it will return 0 on that pin address!
      rd_data <= ( ~(gpio_status_data[addr-1]) & gpio_status_data[addr]);
    end
  end

endmodule
