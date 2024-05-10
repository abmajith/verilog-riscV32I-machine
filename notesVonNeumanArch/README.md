# Short Notes on Von-Neuman Architecture

This repo is about gathering short knowledge on Von-Neuman architecture, 
it is written explicitly with reference from the book "Designing Embedded Hardware" 
by John Catsoulis and "Programming Embedded Systems" by Michael Barr.

Let's start discussing, a picture is worth a thousand words, 

<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/notesVonNeumanArch/archBasicPicture.jpg" alt="J" width="800"/>


In a Von-Neumann architecture, the same address and data bus are used for
reading from and writing to memory. This concept is known as memory-mapped I/O,
where memory and I/O devices are accessed using the same address space. For example, if a processor is designed to have a 32-bit address bus, then it
can address in the range of [0x0000 0000, 0xFFFF FFFF] in hexadecimal number,
which is up to *4GB* of memory.
This address space is typically divided into regions for memory and I/O devices.

- Within this address space, certain ranges are reserved for memory like *RAM, ROM, Flash,*, etc.,
  while other ranges are allocated for I/O devices like *serial ports, GPIO pins, etc*.

- Each memory location and I/O device is assigned a unique address within the address space.

- Not all addresses in the address space are necessarily mapped to valid memory or I/O devices.
  Some portions of address space may be left unused.
  Its not common in computer systems to have as much physical memory as the address space allows for.

In this memory-mapped I/O address space, the block of memory and I/O devices could be seen as 
<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/notesVonNeumanArch/addressspacemmio.jpg" alt="J" width="800"/>


**Memory**
In a Von Neumann architecture, the same *memory* space is used to store program instructions and data
manipulated by the *processor*. The memory is never empty, it always contains something,
whether it be instructions, meaningful data, or random garbage.

Usually, in the system organization, the instructions for the application are kept in a read-only memory region,
so that the processor sequentially reads instructions and executes them. This memory space does not change during the program execution.
The rest of the memory space is used for storing dynamic data, including variables, arrays, and any other data      
structures needed for the application. This portion of memory is read from and written to by the *processor*
as the program executes, and its contents may change over time. 


**Buses**
A *bus* is a physical group of wires or signal lines. Buses allow for the transfer 
of electrical signals between different parts of the system and transfer information. 
The *width* of a bus is the number of signal lines dedicated to the flow of information, 
an 8-bit-wide bus transfers 8 bits of data in parallel.

The *data bus* is bidirectional, the flow of signals (i.e. information) 
happens in both directions, and its direction of signal flow is decided by *processor*.

The *address bus* carries the address, which points to the location in memory 
that the *processor* is attempting to access.  It is done with external circuitry.

The *control bus* carries information from the *processor* about its current access state, 
like the write or read operation. A *processor* might have some input control lines like reset, 
interrupt lines, clock input signal, etc.

The *processor* can write data to memory or an I/O device, read data from memory or 
an I/O device, and read instructions from memory. In memory-mapped I/O, there is no difference 
in writing to memory and I/O, and there is no difference in reading from memory 
and I/O or reading instruction from memory.



**Processor**
A *processor* sometimes also known as a *CPU* (Central Processing Unit), its main functionality is
the reading sequence of instructions from the code block (in the memory region), decoding it, executing it, and store it in
its register or write in *memory* (also I/O blocks). It also handles interrupts from I/O devices.

Let's see some basic building blocks inside the processor and key interrupt handling.

- *ALU*
  - It is responsible for performing arithmetic and logic operations on data.

  - Depending on the processor design, it performs addition, subtraction, multiplication, bitwise *AND*, *OR*,
      shift operations, comparison operations, etc.

  - It takes input from registers or memory and provides the outputs.

- *Registers*
  - Registers are small, fast storage locations within the processor

  - It is used for storing operands, intermediate results, and addresses.

  - Common types are *PC* (program counter), *IR* (instruction register) holds currently fetched instruction, General-purpose
      registers, *SP* stack pointer, *CSR* control and status register holds flags indicating processor status.

  - Depending on the processor design, the existence of these registers, and register width varies a lot.

  - Some *processors* also have *shadow registers*, which save the state of the main registers 
	  when the processor begins servicing an interrupt. It avoids explicitly writing the 
	  temporary register data in the *stack*.

- *Interrupts* (also known as traps or exceptions in some processors) 
	are signals generated by peripheral devices to request attention 
	from the processor, causing the processor to divert from the current 
	execution and deal with the event that has occurred.

  - When an interrupt occurs, the usual procedure is for the processor to save its state 
		by pushing its registers, *PC* onto the stack or *shadow register*. 
		The processor then loads an interrupt vector into the *PC*.

  - The interrupt vector is the address where an interrupt service routine (*ISR*) lies. 
		Thus loading the vector into the program counter, and beginning the execution of the ISR, 
		the last instruction of an *ISR* is always a *Return* from Interrupt instruction. 
		This causes the processor to reload the saved state either from *stack* or *shadow registers*

**Install Verilog and gtkwave in Ubuntu**
I am sorry if you are using other than *Linux*! OS. I never had an opportunity to run other 
*OS* besides watching movies with my friends on their computers.

To install *Verilog, gtkwave*
```bash
#install
sudo apt-get install iverilog gtkwave
#test
gtkwave --version
iverilog -V
```
In other *Linux* distributions, it would be similar.

To have short and effective tutorial on *Verilog* one can follow 
<a href="https://www.chipverify.com/tutorials/verilog" class="custom-link">this tutorial</a>.

**Creating Read Only Instruction Memory in Verilog**
I am just writing the subset of the read-only memory module here,
In the subfolder (*readInstructionOnly*),
code *instructionMemory.v* (represents memory instruction read block),
*instructionMemory_tb.v* (for simulating the instructionMemory module)
*instruction_init.hex* (a dummy sequence of instructions stored).

```verilog
module InstructionMemory # (parameter INST_WIDTH = 32, INST_DEPTH = 1024) 
  (
  input wire clk, 
  input wire [($clog2(INST_DEPTH)-1):0] rd_addr, 
  input wire rd_en, 
  output reg [INST_WIDTH-1:0] instruction
  );
	
  reg [INST_WIDTH-1:0] memory [0:INST_DEPTH-1]; // setting up the required memory

  // This can't be synthesizable, but its here for just simulation
  // Later will see how to write a synthesizable code,
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
```
Note: In the created module, each addressable memory has 32-bit data, not 8-bit data. As long as
we are working with just memory region, it is okay, when we go for memory-mapped I/O,
we have to go with a strict 8-bit data bus. It is not a wise choice to assume I/O devices 
are also 32-bit wide in communication. We will bring the memory alignment into the design 
when we go down the path and build a unified memory module.

```bash
iverilog instructionMemory.v instructionMemory_tb.v -o instrMemSim
# will store the simulation result in file 'InstructionMemory_tb.vcd'
#run gtkwave, navigate the generated file, and click the file
#insert clk, address, rd_en, zoom out, there is your simulation result in signal form
gtkwave
```

**Creating Read and Write Data Memory in Verilog**
In this *Verilog* module, we have to provide *wire* for providing the data to write in the memory, 
as well as *write enable* signal. 

The code is available in the subfolder (*readwriteMemory*),  simulation procedure is same as before. 
```verilog
module ReadWriteMemory #( parameter DATA_WIDTH = 32,parameter DATA_DEPTH = 1024) 
  (
  input wire clk,
  input wire [($clog2(DATA_DEPTH)-1):0] addr, 
  input wire rd_en, input wire wr_en,
  input wire [DATA_WIDTH-1:0] write_data, 
  output reg [DATA_WIDTH-1:0] read_data
  );
	
  reg [DATA_WIDTH-1:0] memory [0:DATA_DEPTH-1];

  // writing into memory
  always @ (posedge clk) begin
    if (wr_en && (addr < DATA_DEPTH)) begin
      memory[addr] <= write_data;
    end
  end
  // reading from memory
  always @ (posedge clk) begin
    if (rd_en && (addr < DATA_DEPTH)) begin
      read_data <= memory[addr];
    end
  end
endmodule
```

For both above examples on this page, I avoided the comments for the module and various lines,
in the folder file, I wrote code with a good number of comments.
Also when you follow the simulation, you will see the typical and importance of simulation.

**Creating Addressable I/O Device in Verilog**
We are not working in real hardware, we will simulate the behavior of I/O devices using
memory! We will see how general-purpose input output pins can be read and written.
The test bed code, and module code are in the sub folder name IOdevice. 

```verilog
module GPIO # (
  // parameter for setting number of sets of 8-pin parallel port
  parameter NUM_GPIO_SETS = 4,
  parameter GPIO_WIDTH    = 8
) (
  input wire clk,
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
  // Note there is 2 times the num of gpio pin set.

  // gpio_status_data[0,2,4,..] for setting GPIO pins read/write status
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

  // setting the enable status (only write) of the GPIO pins
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
      // and never change its value on the actual register
      rd_data <= ( ~(gpio_status_data[addr-1]) & gpio_status_data[addr]);
    end
  end

endmodule
```

There are some other  important I/O devices, like a timer counter for generating periodic interrupt signals,
*UART* (universal asynchronous receiver and transmitter) for a serial port transmission and receiver.

We will develop these important I/O devices and their interrupt mechanism after creating a bare minimum processor, 
aligned memory access for read-only, and read-and-write memory.

**Aligned Memory**
Note, in the earlier memory code (either read instruction only or read-write memory modules),
modules are written in a parameter way so that we can modify the data width, address width, 
and depth of those data areas. A valid address is mapped to the data, 
it is parameterized to have a certain data width in that module instance.

In the memory blocks, each byte should be addressable separately, not specifically 2 bytes, 
four bytes, or 8 bytes. Memory blocks like *SRAM, RAM, ROM, flash memory, etc,* 
are not just designed for one specific architecture style but more for a general case.

So let's work on the aligned memory space module

```verilog
```

**Parts of Processor**

*Processor Registers*:
For the *RV32I* base format, we have 32-bit, 32 registers, among them the first register is always mapped to zero, let's create them
in Verilog


```verilog
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
```

Here, note all the ports to this registerfile module are wire type.
In the subfolder, I do have a test bench for this module, do as many simulations as possible to understand the behavior,
change a few things, to grasp the module behavior, it will make us ready for building forthcoming building blocks.

Here I will show the timing diagram of write and read from registerFile module (generated by gtkwave)

<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/notesVonNeumanArch/processorBlocks/registerWrite.png" alt="J" width="800"/>

<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/notesVonNeumanArch/processorBlocks/registerRead.png" alt="J" width="800"/>


*Processor Instruction Decoder*:
Now, let's see a simple decoder for the instruction, the decoder of the processor 
is easiest to design (of course, when we use open source encoding scheme such as *RV32I*),
the main goal behind is from the instruction, separating various fields, 
for the *RV32I* base format, we have to deal with six type of encoding format, 
and extracting the *immediate, opcode, funct3, funct7, rd, rs1, rs2* fields, 
and also few more extra enabling signals to notice the other part of the processor, 
what are the valid signals, and what's not!.

Here is the simple one, note it is as important to test and do verification, 
especially since this is not a complex code, but organizing the input instruction, 
I recommend verifying this code by two-stage, first consider whether you extracted 
the enable signal correct for the given instruction type  (*I, J, B, S, L, R* type instruction), 
then various fields (*immediate, opcode, funct3, funct7, rd, rs1,rs2*).
I wrote a simple test bench and *decode* module (in the subfolder processorblocks).


```verilog
module decode (
  // instruction to decode
  input [31:0] instruction,

  // couple of register address to read and write
  output reg   rg_we, // register write enable
  output [5:0] rd_addr,
  output reg   rg_re1, // use rs1_addr enable
  output [5:0] rs1_addr,
  output reg   rg_re2, // use rs2_addr enable
  output [5:0] rs2_addr,

  // opcode
  output [6:0] opCode,
  // func3, funct7
  output [2:0] funct3,
  output [6:0] funct7,
  output reg [31:0] immediateExtd
);

  // internal signals

  // if inst is *I-type* instruction
  wire [31:0] Iimm = { {21{instruction[31]}}, instruction[30:20]};
  // if inst is *S-type* instruction
  wire [31:0] Simm = { {21{instruction[31]}}, instruction[30:25], instruction[11:7]};
  // if inst is *B-type* instruction
  wire [31:0] Bimm = { {20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
  // if inst is *U-type* instruction
  wire [31:0] Uimm = { instruction[31:12], {12{1'b0}}};
  // if inst is *J-type* instruction
  wire [31:0] Jimm = { {12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};


  // consistency in the placement of other fields in the instruction, makes easier to extract the details as
  // extracting opcode, funct3, funct7
  assign opCode = instruction[6:0];
  assign funct3 = instruction[14:12];
  assign funct7 = instruction[31:25];
  // extracting register address fields
  assign rd_addr  = {instruction[11:7]};
  assign rs1_addr = {instruction[19:15]};
  assign rs2_addr = {instruction[24:20]};


  // extracting the immediate field into extended immediate format as disuccused in the documents
  // also set up the enable for register address rd, rs1, rs2.
  always @ (*) begin
    case (instruction[6:0])
      7'b0110111: begin // LUI U-type instruction
        immediateExtd = Uimm;
        rg_we = 1'b1;
        rg_re1 = 1'b0;
        rg_re2 = 1'b0;
      end

      7'b0010111: begin // AUIPC U-type instruction
        immediateExtd = Uimm;
        rg_we = 1'b1;
        rg_re1 = 1'b0;
        rg_re2 = 1'b0;
      end

      7'b1101111: begin // JAL J-type instruction
        immediateExtd = Jimm;
        rg_we = 1'b1;
        rg_re1 = 1'b0;
        rg_re2 = 1'b0;
      end

      7'b1100111: begin // JALR I-type instruction
        immediateExtd = Iimm;
        rg_we = 1'b1;
        rg_re1 = 1'b1;
        rg_re2 = 1'b0;
      end

      7'b1100011: begin // branch B-type instruction
        immediateExtd = Bimm;
        rg_we = 1'b0;
        rg_re1 = 1'b1;
        rg_re2 = 1'b1;
      end

      7'b0000011: begin // load I-type instruction
        immediateExtd = Iimm;
        rg_we = 1'b1;
        rg_re1 = 1'b1;
        rg_re2 = 1'b0;
      end

      7'b0100011: begin // store S-type instruction
        immediateExtd = Simm;
        rg_we = 1'b0;
        rg_re1 = 1'b1;
        rg_re2 = 1'b1;
      end

      7'b0010011: begin // immediage arithmetic operations type
        immediateExtd = Iimm;
        rg_we = 1'b1;
        rg_re1 = 1'b1;
        rg_re2 = 1'b0;
      end

      7'b0110011: begin // arithemtic operation on register type
        immediateExtd = 32'b0;
        rg_we = 1'b1;
        rg_re1 = 1'b1;
        rg_re2 = 1'b1;
      end

      7'b0001111: begin // fench type, not implemented here or documented
        immediateExtd = 32'b0;
        rg_we = 1'b0;
        rg_re1 = 1'b0;
        rg_re2 = 1'b0;
      end
      7'b1110011: begin // system type, not implemented here or doucmented
        immediateExtd = 32'b0;
        rg_we = 1'b0;
        rg_re1 = 1'b0;
        rg_re2 = 1'b0;
      end

      default: begin // default execution
        immediateExtd = 32'b0;
        rg_we = 1'b0;
        rg_re1 = 1'b0;
        rg_re2 = 1'b0;
      end

    endcase // for case

  end // for always

endmodule
```
