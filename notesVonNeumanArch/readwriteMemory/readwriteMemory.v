module ReadWriteMemory 
	#(
	// data width
	parameter DATA_WIDTH = 32,
	// number of DATA_WIDTH
	parameter DATA_DEPTH = 1024
	) (
	// clock signal
	input wire clk,
	// address to read or write data
	input wire [($clog2(DATA_DEPTH)-1):0] addr,
	// enable read data
	input wire rd_en,
	// enable write data
	input wire wr_en,
	// if it is write provide the data
	input wire [DATA_WIDTH-1:0] write_data,
	// read data
	output reg [DATA_WIDTH-1:0] read_data
	);

	// define read write data memory
	reg [DATA_WIDTH-1:0] memory [0:DATA_DEPTH-1];

	// write operation
	always @ (posedge clk) begin
		if (wr_en && (addr < DATA_DEPTH)) begin
			memory[addr] <= write_data;
		end
	end

	// read operations
	always @ (posedge clk) begin
		if (rd_en && (addr < DATA_DEPTH)) begin
			read_data <= memory[addr];
		end
	end
endmodule
