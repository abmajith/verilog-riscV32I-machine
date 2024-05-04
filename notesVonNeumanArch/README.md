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
which is up to (*4GB* of memory).
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
