# verilog-riscV32I-machine


*This repo is about Learning  RISC V 32 integer base instruction sets and implement in verilog*

*RISC-V* (say risk-five) is an open source instruction set architecture (*ISA*) based on 
*RISC* (reduced instruction set computing). Here will just study how (and not why) a particular base *RV32I* 
(*RISC-V* 32 bit Integer Instruction set) constructed. We will dicover on why part (well for mostly simplicity and simple hardware implementation) of this Instruction set after
we know how *RV32I* encoded and know how to implement these instructions in a verilog simulator and possibly in a FPGA board.


*RV32I* Instruction set classifed into 7 classes, they are

**Arithmetic Instructions** like addition, subtraction, multiplication, division, and bitwise operations.

**Load and Store Instructions** deals with loading data from memory to register, and store data from register to memory (or I/O devices based on address).

**Control Transfer Instructions** deals in flow of program, they are conditional (think of if else statement based on register value), unconditional (strict jump), 
procedure calls  and returns (for functions, interrupt service routine application calls). 

**Data Transfer Instructions** move data within registers or performing operations on data within registers.

**Immediate Instructions** special type instructions (confuse to understand at first, once we understand the encoding scheme of opcode, it is quite straight forward) perform on the 
instruction itself (part of data extracted from the instruction encoding).

**Shift Instructions** logical and arithmetic shifts on register data.

**Comparison Instructions** comparing register datas or register data with immediate value (part of data extracted from instructions).

These classification are classifed based on how we naturally classify set assembly instructions more human readable way. 
If we actually classify these instructions based on the encoding scheme, it will be totally 11 classes, before introducing these 11 classes further, 
we will go thorough some well known instructions and how its encoding looks like,

It is better to emphasize here that in *RV32I*, it supports 32, 32 bit registers (named as *X0, X1, ....X31*) and one program counter register (*PC*). 
Note, there is no special link register (*LR*) or stack pointer (*SP*) (it is upto the open source ISA based hardware designer), nonetheless, often *X1,X2* are used for *LR, SP*. 
One more information to note, register *X0* is hardwired to *zero*, you can't expect to store any data there, but its existence shows its advantage once we 
know some knowledge on *RISC-V*, and its instruction simplicity!.

Quiz: How many bits are needed to address these 32 registers?: Ans: 5 Well, joking, ofcourse I should not write this trival question, when you know the word *RISC V, Verilog*!

**FEW Instructions Example**
add X3, X1, X2   // Add data of registers X1 and X2, and store in register X3
Equivalent Encoding is  00000000  rs2 rs1 000 rd 0110011, where rs2, rs1, rd are the 5 bit address to the registers *X2,X1* and *X3*.,

sub x3, x1, x2   // Subtract data of register X2 from register X1, and store in register X3
Equivalent Encoding is  0100000 rs2 rs1 000 rd 0110011

mul x3, x1, x2   // Multiply the contents of registers X1 and X2, and store  in register x3
Encoding is 0000001 rs2 rs1 000 rd 0110011

div x3, x1, x2   // Divide the contents of register x1 by register x2, and store in register x3
0000001 rs2 rs1 100 rd 0110011

rem x3, x1, x2   // Calculate the remainder when the contents of register x1 is divided by register x2, and store the result in register x3
0000001 rs2 rs1 110 rd 0110011

Encoding itself contains information about what registers we are operating (5bit: 00000 refers to *X0*, 00001 referst to *X1*, and so on).
To dicuss more, lets write this encoding in abstract variable format

Funct7 rs2 rs1 Funct3 rd Opcode7,  add the subscript of Funct, Opcode + 15 (a 3, 5 bit address for register mapping) will get 32. 
Few more observations, only difference between addition and subtraction is the 2 MSB of the opcode, all the rest are same. 


