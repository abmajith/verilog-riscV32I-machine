# Short Notes on Von-Neuman Architecture

This repo is about gathering primitive knowledge on Von-Neuman architecture 
and providing *Verilog* simulation of various components,  
it is written explicitly with reference from the book "Designing Embedded Hardware" 
by John Catsoulis and "Programming Embedded Systems" by Michael Barr.

Let's start discussing, a picture is worth a thousand words, 

<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/RV32I_VonNeumanArch/archBasicPicture.jpg" alt="J" width="800"/>


As in the above picture, Von-Neumann architecture has a simplified address space, 
the processor communicates with both memory and I/O devices through the same address and data bus. 
The address space is typically divided into regions for memory and I/O devices. 
This division allows the processor to distinguish between memory accesses and I/O operations. 
For example, addresses in a certain range might correspond to memory locations, 
while addresses in another range might correspond to registers of I/O devices.


If a processor is designed to have a 32-bit address bus, then it
can address in the range of [0x0000 0000, 0xFFFF FFFF] in hexadecimal number,
which is up to *4GB* of memory.

- Within this address space, certain ranges are reserved for memory like *RAM, ROM, Flash,*, etc.,
  while other ranges are allocated for I/O devices like *serial ports, GPIO registers, etc*.

- Each memory location and I/O device is assigned a unique address within the address space.

- Not all addresses in the address space are necessarily mapped to valid memory or I/O devices.
  Some portions of address space may be left unused.
  Its not common in computer systems to have as much physical memory as the address space allows for.

In this memory-mapped I/O address space, the block of memory and I/O devices could be seen as 
<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/RV32I_VonNeumanArch/addressspacemmio.jpg" alt="J" width="800"/>


**Memory**
In a Von Neumann architecture, the *memory* space is used to store program instructions and data
manipulated by the *processor*. The memory is never empty, it always contains something,
whether it be instructions, meaningful data, or random garbage.

Usually, in the embedded system organization, the instructions for the application 
are kept in a read-only memory region, so that the processor sequentially reads 
instructions and executes them. This memory space does not change during 
the program execution. The rest of the memory space is used for storing dynamic data, 
including variables, arrays, and any other data structures needed for the application. 
This portion of memory is read from and written to by the *processor* as the program executes, 
and its contents may change over time. 


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
A *processor* sometimes also known as a *CPU* (Central Processing Unit), 
its main functionality is the reading sequence of instructions from the code block 
(in the memory region), decoding it, executing it, and store it in
its register or write in *memory* (also I/O blocks). It also handles interrupts from I/O devices.

Let's see some basic building blocks inside the processor and key interrupt handling.

- *ALU*
  - It is responsible for performing arithmetic and logic operations on data.

  - Depending on the processor design and instruction set, it performs addition, 
    subtraction, multiplication, bitwise *AND*, *OR*, 
    shift operations, comparison operations, etc.

  - It takes input from registers or memory and provides the outputs.

- *Registers*
  - Registers are small, fast storage locations within the processor

  - It is used for storing operands, intermediate results, and addresses.

  - Common types are *PC* (program counter), *IR* (instruction register) 
    holds currently fetched instruction, General-purpose
    registers, *SP* stack pointer, *CSR* control and status register holds 
    flags indicating processor status.

  - Depending on the processor design, the existence of these registers, 
    and register width varies.

  - Some *processors* also have *shadow registers*, which save the state of 
    the main registers when the processor begins servicing an interrupt. 
    It avoids explicitly writing the temporary register data in the *stack*.

- *Interrupts* (also known as traps or exceptions in some processors) 
	are signals generated by peripheral devices to request attention 
	from the processor, causing the processor to divert from the current 
	execution and deal with the event that has occurred.

  - When an interrupt occurs, the processor typically saves its state by pushing 
    register values onto a shadow register or the stack, and then loads an interrupt 
    vector into the program counter (*PC*).

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

If someone wants solid understanding of *Verilog* syntax, and  
what is the standard procedure for digital system design, I refer to the book
*Verilog HDL: A Guide to Digital Design and Synthesis* by *Samir Palnitkar*.



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
we have to go with an 8-bit aligned memory. It is better not to assume I/O devices        
are also 32-bit wide in communication. So only part of the data bus is wired with I/O devices.

We will bring the memory alignment into the design when we go down the path and 
build a unified memory module.


```bash
iverilog instructionMemory.v instructionMemory_tb.v -o instrMemSim
# will store the simulation result in file 'InstructionMemory_tb.vcd'
#run gtkwave, navigate the generated file, and click the file
#insert clk, address, rd_en, zoom out, there is your simulation result in signal form
gtkwave
```

<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/RV32I_VonNeumanArch/readInstructionOnly/readInstructionOnlyClk.png" alt="J" width="800"/>
In the above read only instruction memory module, it is designed in a way that,
when a clock signal goes from negative to positive (denoted as a positive edge) 
and read enable is active high, it loads the data from the address space onto the processor. 
Its value stays until the change in address or read enable is set 
to low. Even if there is a change in address between the positive edges, 
reading the data from the new address only happens at the positive edge never in between.



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

<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/RV32I_VonNeumanArch/readwriteMemory/readWriteData.png" alt="J" width="800"/>


The above read and write memory module is programmed when read enable is active high, 
it loads the data from the memory address onto the processor at the positive edge 
of the clock. Similarly, it writes the data onto the memory address at the positive 
edge of the clock if the write enable is activated.



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
  // gpio_status_data[1,3,5,..] for actual GPIO pins data storage

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

  // setting the enable status (only write) of the GPIO pins on the odd numbered byte
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

The above module for *GPIO* is written with the knowledge of typical GPIO pin construction in modern 
embedded boards (if you already worked in STM Nucleo board, there is a contiguous memory for each 8-pin 
port like GPIO ports A, B, C,..., there is a well-defined address to set the status of the pins and 
an address to read/write data from/to the port pins).


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
are not just designed for one specific architectural style but more for a general case.

So let's work on the aligned memory space module (in little-endien), the code is available 
in the subfolder *processorBlocks* with the test bench


```verilog
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
```
In the above module, we load the aligned 4 bytes of instruction from the address (should be divisible by 4)
instantaneously as soon as the address changes, and we have an additional signal to indicate the validity 
of the instruction, if the address memory is out of range, we made this signal to indicate that the address 
is not in a valid range.

<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/RV32I_VonNeumanArch/processorBlocks/alignedInstructionMemory.png" alt="J" width="800"/>

This module is designed such that the instruction is loaded as soon as the address changes,
it is not synched with the clock but synched with the address.


```verilog
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
  input [1:0]  wr_mode, // mode 0, single byte, 1 for half word, 2 for full word

  // read address with enable signal, and number of bytes
  input [31:0] rd_addr,
  input        rd_en,
  input [1:0]  rd_mode,
  output [31:0] rd_data
  );

  reg [7:0] mem [START_ADDRESS:STOP_ADDRESS];

  always @ (posedge clk) begin
    if (wr_en) begin
      // there is atleast one byte to write
      mem[wr_addr+0] <= wr_data[7:0];
      mem[wr_addr+1] <= (wr_mode[0])   ? wr_data[15:8]  : mem[wr_addr+1];
      mem[wr_addr+2] <= (wr_mode[1])   ? wr_data[23:16] : mem[wr_addr+2];
      mem[wr_addr+3] <= (wr_mode[1])   ? wr_data[31:24] : mem[wr_addr+3];
      // note here this block is writing without alignment constraints
    end
  end
  assign rd_data[7:0]   = (rd_en)                 ? {mem[rd_addr+0]} : 8'b0;
  assign rd_data[15:8]  = (rd_en && rd_mode[0])   ? {mem[rd_addr+1]} : 8'b0;
  assign rd_data[23:16] = (rd_en && rd_mode[1])   ? {mem[rd_addr+2]} : 8'b0;
  assign rd_data[31:24] = (rd_en && rd_mode[1])   ? {mem[rd_addr+3]} : 8'b0;

  // right now there is no check for valid memory area, it could be added by adding two more signals in the port list
  // will keep it simple now, later we will expand, depends on the need!
endmodule
```

<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/RV32I_VonNeumanArch/processorBlocks/readByteMemory_pr1.png" alt="J" width="800"/>
<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/RV32I_VonNeumanArch/processorBlocks/readByteMemory_pr2.png" alt="J" width="800"/>

In the above module, based on the write/read mode, it can read/write a byte, half-word, and word. Writing the provided data
at the address is done on the positive edge. Whereus reading the data from the address is done instantaneously.

**Internal Modules of Processor**

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

  // write enable logic, provided data is loaded into register at positive edge of clk
  always @(posedge clk or posedge rst) begin
    if (we && (~rst)) begin
      if ( (0 < rd_addr) && (rd_addr < REG_DEPTH) ) begin
        bank[rd_addr] <= rd_value;
      end
    end
  end

  // Read assignment statement, assigned instantaneously (well in real hardware with some propagation delay)
  assign rs1_value = (~rst && |rs1_addr) ? bank[rs1_addr] : 0;
  assign rs2_value = (~rst && |rs2_addr) ? bank[rs2_addr] : 0;
endmodule
```

Here, note all the ports to this registerfile module are wire type.
In the subfolder, I do have a test bench for this module, do as many simulations as possible to understand the behavior,
change a few things to grasp the module behavior, it will make us ready for building forthcoming building blocks.

Here I will show the timing diagram of write and read from registerFile module (generated by gtkwave)

<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/RV32I_VonNeumanArch/processorBlocks/registerWrite.png" alt="J" width="800"/>
Provided *rd_value* is loaded into the *rd_addr* at positive edge of the clock signal if the write enable signal *we* is active

<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/RV32I_VonNeumanArch/processorBlocks/registerRead.png" alt="J" width="800"/>
As soon as the *rs1_addr,rs2_addr* changes *rs1_value,rs2_value* respectively signals reflect the corresponding register data.


*Processor Instruction Decoder*:
Now, let's see a simple decoder for the instruction, the decoder of the processor 
is almost trival to design (of course, when we use open source encoding scheme such as *RV32I*),
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
  output [4:0] rd_addr,
  output reg   rg_re1, // use rs1_addr enable
  output [4:0] rs1_addr,
  output reg   rg_re2, // use rs2_addr enable
  output [4:0] rs2_addr,

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

Let's discuss the instruction loading unit and decoder from the above modules.
As we have seen the module *ByteAlignInstructionMemory*, for the given input address *iaddr* 
(indicated by program counter register), it signals the 4 bytes instruction output, 
using the above *decode* module, we can extract the various signals instruction signals like *opcode,funct3,funct7,etc* 
as show in the following picture.

<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/RV32I_VonNeumanArch/instructiondecodePCblock.jpg" alt="J" width="800"/>


Let's see how we will combine instruction loading from byte aligned instruction memory and decode modules 
as guided by the above picture

```verilog
module processor(
  // clock signal
  input clk,
  // reset signal active high
  input rst);

  // program counter act as instruction address
  reg [31:0] PC;

  // for holding current instruction and its validity
  wire [31:0] inst;
  wire        isValidInst;

  // couple of wires to hold current instruction fields signals
  wire [6:0] opCode;
  wire [2:0] funct3;
  wire [6:0] funct7;
  wire [31:0] immediate_value;

  // register source and destination address and its mode signals for the current instruction
  wire [4:0] rs1_ad;
  wire [4:0] rs2_ad;
  wire [4:0] rd_ad;

  wire is_wr_en; // destination register write
  wire is_rd_en1; // first register source read
  wire is_rd_en2; // second register source read

  // based on opcode, hold instruction type by assign the following wires
  wire is_alu_reg  = (inst[6:0] == 7'b0110011);
  wire is_alu_imm  = (inst[6:0] == 7'b0010011);
  wire is_load     = (inst[6:0] == 7'b0000011);
  wire is_store    = (inst[6:0] == 7'b0100011);
  wire is_branch   = (inst[6:0] == 7'b1100011);
  wire is_jalr     = (inst[6:0] == 7'b1100111);
  wire is_jal      = (inst[6:0] == 7'b1101111);
  wire is_lui      = (inst[6:0] == 7'b0110111);
  wire is_auipc    = (inst[6:0] == 7'b0010111);
  wire is_system   = (inst[6:0] == 7'b1110011);
  wire is_fence    = (inst[6:0] == 7'b0001111);
  wire is_invalid  = (isValidInst || is_fence ||  // you are correct, we are not dealing with fence instruction!
                          !(
                            is_alu_reg || is_alu_imm || is_load || is_store ||
                            is_branch || is_jalr || is_jal || is_lui || is_auipc || is_system
                           )
                     );

  // instruction memory

  ByteAlignInstructionMemory #(
        .START_ADDRESS(0),
        .STOP_ADDRESS(1023) // holds block of 1KB memory, which can hold upto 256 RV32I instructions
      ) instMem (
        // clock signals
        .clk(clk),

        // instruction address
        .iaddr(PC),
        .instruction(inst),
        .isValid(isValidInst)
      );

  // create a decode module instance
  decode instDecoder (
    // instruction wiring
    .instruction(inst),

    // register address and mode circuit wiring
    .rg_we(is_wr_en),
    .rd_addr(rd_ad),
    .rg_re1(is_rd_en1),
    .rs1_addr(rs1_ad),
    .rg_re2(is_rd_en2),
    .rs2_addr(rs2_ad),

    // instruction field wiring
    .opCode(opCode),
    .funct3(funct3),
    .funct7(funct7),
    .immediateExtd(immediate_value)
  );

endmodule
```
- The *processor* module manages the program counter (*PC*) to fetch instruction from memory and decode them.
- The *ByteAlignInstructionMemory* module handles the instruction memory, ensuring that the correct instruction
  is fetched based on the *PC* value.
- The *decode* module decodes the fetched instruction to extract various fields like *opcode, funct3, funct7*, and
  immediate values.
- Various control signals (*is_wr_en, is_rd_en1, is_rd_en2*) are generated based on the instruction type.


Here is the main idea, at fetch decode phase, *PC* is used to fetch the instruction from memory, the instruction 
memory provides the instruction and its validity based on the current *PC* value.
Using combinational decode circuit, *decode* module immediately process the instruction to extract various instruction 
fields and control signals. The decode is almost instance, in real hardware, combinational circuit have some 
propagation dealy, it can be neglected with clock cycle duration is reasonably longer than this delay. 

<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/RV32I_VonNeumanArch/processorBlocks/fetchDecodePhase.jpg" alt="J" width="800"/>


*Arithmetic Logic Unit* (ALU), In *RV32I* base instruction format, there are around 40 instructions,
among them, 19 arithmetic instructions (10 perform only on registers and 9 with immediate and registers value). 

Let's write them in simple modular form to do just arithmetic operations in combinational logic circuit, 
hide the details of instruction type, pass the two operands, and get back the arithmetic results and status values. 

```verilog
module IV32IALU
  (
  // control unit to execute alu or not
  input wire  alu_execute,
  // there are two operands
  input wire [31:0] op_a,
  input wire [31:0] op_b,
  // funct3 code
  input wire [2:0]  funct3,
  // sign bit to perform add/sub or logical/arithmetic right shift
  input wire        op_sign,
  // some additional aritmetic results
  output wire zero,
  output wire negative,
  output reg overflow,
  output reg [31:0] result
  );
  
  // internal signals
  wire [31:0] sum;
  wire [32:0] minus;
  wire        LT;
  wire        LTU;
  wire [4:0]  shamt;

  // if subtract use one's complement and add one otherwise normal sum
  assign sum      = op_a + op_b;
  assign minus    = {1'b0, op_a} + {1'b1, ~op_b} + 33'b1;
  assign zero     = (|result) ? 1'b0 : 1'b1; // if the result is zero, set the zero wire
  assign negative = result[31];
  assign LT       = (op_a[31] ^ op_b[31]) ? op_a[31] : minus[32];
  assign LTU      = minus[32];
  assign shamt    = op_b[4:0];
  
  
  always @(*) begin
    if (alu_execute) begin
      overflow  = (op_sign)  ? ((op_a[31] ^ op_b[31]) & (op_a[31] ^ minus[31])) : 
                                ~(op_a[31] ^ op_b[31]) & (op_a[31] ^ sum[31]);
    end else begin
      overflow = 1'b0;
    end
  end

  always @ (*) begin
    if (alu_execute) begin
      case(funct3)
        // subtraction/addition
        3'b000: result = (op_sign) ? minus[31:0] : sum;
        // sll
        3'b001: result = (op_a << shamt);
        // slt
        3'b010: result = {31'b0, LT};
        // sltu
        3'b011: result = {31'b0,LTU};
        // xor
        3'b100: result = (op_a ^ op_b);

        // sra/srl
        3'b101: result = (op_sign) ? ($signed(op_a) >>> shamt) : ($signed(op_a) >> shamt); 

        // or
        3'b110: result = (op_a | op_b);
        // and
        3'b111: result = (op_a & op_b);

        default: result = 32'b0;

      endcase
    end else begin
      result = 32'b0;
    end // if else
  end // always

endmodule
```

Let's see verilog code snippet to add on the processor module for loading the operands 
from register file and execute alu combinational circuit
```verilog
module processor
...
  // to set the write back to the register banks
  reg en_wr = 1'b0;  // default
  // couple of wires to signal 32-bit value
  wire [31:0] rs1_value;
  wire [31:0] rs2_value;
  wire [31:0] rd_value;

  //registerfile instance
  registerFile # (
      .REG_DEPTH(32),
      .REG_WIDTH(32),
      .RADDR_WIDTH(5)
    )  regBank (
      // clock and reset signals
      .clk(clk),
      .rst(rst),
      // writing the result mode?
      .we(en_wr),
      // source and destinatin register address
      .rs1_addr(rs1_ad),
      .rs2_addr(rs2_ad),
      .rd_addr(rd_ad),
      .rd_value(rd_value),
      .rs1_value(rs1_value),
      .rs2_value(rs2_value)
    );
  // for making the appropriate operands for the instruction
  reg [31:0] op_a;
  reg [31:0] op_b;

  // couples of signals and registers for alu unit
  wire        alu_zero;
  wire        alu_negative;
  wire        alu_overflow;
  wire [31:0] alu_result;
  wire op_sign = inst[30];
  wire alu_execute = (is_alu_reg || is_alu_imm) ? 1'b1 : 1'b0;

  // alu instance
  IV32IALU alu (
        // control signals
        .alu_execute(alu_execute),
        // operands and function code
        .op_a(op_a),
        .op_b(op_b),
        .funct3(funct3),
        .op_sign(op_sign),
        // alu output with some flags
        .zero(alu_zero),
        .negative(alu_negative),
        .overflow(alu_overflow),
        .result(alu_result)
    );

...
endmodule
```

Let's grasp the register loading and performing arithmetic operations in the block diagram as below.

<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/RV32I_VonNeumanArch/registerALUBlocks.jpg" alt="J" width="800"/>


At this moment we have a module for *memory, ALU, Register, and instruction decoder*, we can proceed to build a processor
that executes the *RV32I* base instruction set, all it has to do is bind all the modules so far created
and form extra logic for performing load/store data from/to memory (RAM), jump and link registers instruction logic, 
and branch instruction logic. The design principle we followed is called the modular and bottom-up approach. We
discussed a bit about processor and memory access, without looking into the block diagram of a processor.
Here, for the first time, we will draw a block diagram for a processor with various blocks like
*memory, ALU, Register, decoder, PC, control and status register, etc.*

<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/RV32I_VonNeumanArch/proc_internals.jpg" alt="J" width="1200"/>
