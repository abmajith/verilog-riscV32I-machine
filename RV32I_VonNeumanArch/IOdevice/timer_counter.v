


module TimerCounter module # (
  // parameter for setting number of sets of 8-pin parallel port
  parameter NUM_TIMER_COUNTER_SETS = 4,
  parameter TIMER_COUNTER_WIDTH    = 8 // minimum 4 bits
) (
  // clock signal
  input wire clk,
  // reset a timer counter 
  input wire rst,
  // address space for parallel ports and enable mode (read or write)
  input wire [$clog2(NUM_TIMER_COUNTER_SETS)+1:0] addr,
  input wire [TIMER_COUNTER_WIDTH-1:0]            wr_data,
  output reg [TIMER_COUNTER_WIDTH-1:0]            rd_data
);
  // various timer_counter addressable I/O device
  reg [TIMER_COUNTER_WIDTH-1:0]  timer_counter [0:(4*NUM_TIMER_COUNTER_SETS)-1];
  // timer_counter[0,1,2,3], 0,  first timer Max Value, writable
  // 1, least third LSB's for count up/down, and En/Not En, interrupt ocurred or not
  // 2, timer_counter[2] store the timer period in clock cycles
  // 3, timer_counter[3] store the current count value
  // and so on
	
  // reset a timer counter at given addressed timer
  always @ (posedge clk) begin
    if (rst && !addr[0] && !addr[1]) begin
      timer_counter[addr+0] <= 0;
      timer_counter[addr+1] <= 0;
      timer_counter[addr+2] <= 0;
      timer_counter[addr+3] <= 0;
    end
   end
  always @ (posedge clk) begin
    if (!)
  end
endmodule

