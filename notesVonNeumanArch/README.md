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

In this memory-mapped I/O address space, the block of memory and I/O devices could be seen as 
<img src="https://github.com/abmajith/verilog-riscV32I-machine/blob/main/notesVonNeumanArch/addressspacemmio.jpg" alt="J" width="800"/>


**Processor**
A *processor* sometimes also known as a *CPU* (Central Processing Unit), its main functionality is
the reading sequence of instructions from the code block (in the memory region), decoding it, execute it, and store it in
its register or write in *memory* (also I/O blocks).

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


