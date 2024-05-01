# verilog-riscV32I-machine


*This repo is about Learning  RISC V 32 integer base instruction sets and its verilog implementation*

*RISC-V* (say risk-five) is an open source instruction set architecture (*ISA*) based on 
*RISC* (reduced instruction set computing). Here will go through how (and not why) a particular base *RV32I* 
(*RISC-V* 32 bit Integer Instruction set) constructed. We will dicover on why part (well for mostly simplicity and respective hardware implementation) after
we know how *RV32I* encoded and know how to implement these instructions in a verilog simulator and possibly in a FPGA board.


*RV32I* Instruction set classifed into 7 classes (by simple human readable way), they are

**Arithmetic Instructions** like addition, subtraction, multiplication, division, and bitwise operations.

**Load and Store Instructions** deals with loading data from memory to register, and store data from register to memory (or I/O devices based on address).

**Control Transfer Instructions** deals in flow of program, they are conditional (think of if else statement based on register value), unconditional (strict jump), 
procedure calls  and returns (for functions, interrupt service routine application calls). 

**Data Transfer Instructions** move data within registers or performing operations on data within registers.

**Immediate Instructions** special type instructions (confuse to understand at first, once we understand the encoding scheme of opcode, it is quite straight forward) perform on the 
instruction itself (part of data extracted from the instruction encoding).

**Shift Instructions** logical and arithmetic shifts on register data.

**Comparison Instructions** comparing register datas or register data with immediate value (part of data extracted from instructions).

If we actually classify these instructions based on the encoding scheme, it will be totally 11 classes, before introducing these 11 classes further, 
we will go thorough some well known instructions and how its encoding looks like,

It is better to emphasize here that *RV32I* base instruction supports 32 registers of each has 32 bits length (named as *X0, X1, ....X31*) and one program counter register (*PC*). 
Note, there is no special link register (*LR*) or stack pointer (*SP*), nonetheless, hardware designer often reserve *X1,X2* for *LR, SP* purpose. 
One more thing to note, register *X0* is hardwired to *zero*, you won't store data in *X0*, it is defined as it is to limit the number of instructions in *RV32I* base format.

Quiz: How many bits are needed to address these 32 registers?: Ans: 5.

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
Lets write these example encoding in abstract variable format *Funct7 rs2 rs1 Funct3 rd Opcode7*,  adding the subscript of two Funct, Opcode (7,3, 7) + 15 (a 3, 5 bit address for register mapping) will get 32. It shows the general Encoding pattern involved in arithmetic operations that load and store data within registers.

An arithmetic operation instruction, a 32 bit length (say bit [31,30,....0]), subfield (sub field bits) [6:0] represents 7 bits wide *opcode*, [11:7] 5 bits wide destination register address, [14:12] a 3 bits wide *funct3* [19:15], [24:20] a two 5 bits wide represents first and second source register address respectively, and [31:25] represents *funct7*.  

**Base Instruction Formats**
There are 4 core instruction formats (R/I/S/U) in *RV32I*, lets list them here.
**R-type** Encoding format *funct7     rs2 rs1 funct3 rd       opcode* 
**I-type** Encoding format *imm[11:0]      rs1 funct3 rd       opcode*, here imm[11:0]  is a 12 bits wide, extracted from the instruction [31:20] subfield.
**S-type** Encoding format *imm[11:5]  rs2 rs1 funct3 imm[4:0] opcode*, here imm[11:0]  is a 12 bits wide, extracted by two subfield parts [31:27] and [11:7] from the instruction.
**U-type** Encoding format *imm[31:12]                rd       opcode*, here imm[31:12] is a 20 bits wide, extracted from the instruction [31:12].

So far, we know rs2, rs1 represents second and first register source address, rd represents destination register address.
imm is a 32 bits value (data or address), the reason why we have two parts imm[31:12] and imm[11:0] in the instruction set is, we can't load 32 bit value (either address or data from memory) in a single instruction cycle into register, it is a clever way of having two instructions to load a single 32 bit into register from memory or I/O. 

Now we will see what *opcode, funct3 and funct7* represents in the instruction.
