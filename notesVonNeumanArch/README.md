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

**Creating Read Only Instruction memory in Verilog**
I am just writing the subset of the read-only memory module here,
In the subfolder (*readInstructionOnly*),
code *instructionMemory.v* (represents memory instruction read block),
*instructionMemory_tb.v* (for simulating the instructionMemory module)
*instruction_init.hex* (a dummy sequence of instructions stored).

```verilog
module InstructionMemory # (parameter INST_WIDTH = 32, INST_DEPTH = 1024) 
	(input wire clk, input wire [($clog2(INST_DEPTH)-1):0] rd_addr, input wire rd_en, 
			output reg [INST_WIDTH-1:0] instruction);
	reg [INST_WIDTH-1:0] memory [0:INST_DEPTH-1]; // setting up the required memory

	// This can't be synthesizable, but its here for just simulation
	// Letter will see how to write a synthesizable code, so that it can be tested on real hardware
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

```bash
iverilog instructionMemory.v instructionMemory_tb.v -o instrMemSim
# will store the simulation result in file 'InstructionMemory_tb.vcd'
#run gtkwave, navigate the generated file, and click the file
#insert clk, address, rd_en, zoom out, there is your simulation result in signal form
gtkwave
```
