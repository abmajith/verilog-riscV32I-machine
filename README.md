# verilog-riscV32I-machine


*This repo is about Learning  RISC V 32 bit integer base instructions set and its verilog implementation*

*RISC-V* (say risk-five) is an open source instruction set architecture (*ISA*) based on 
*RISC* (reduced instruction set computing). Here will go through how (and not why) a particular base *RV32I* 
(*RISC-V* 32 bit Integer Instruction set) constructed. We will dicover on why part (well for mostly simplicity and respective hardware implementation) after
going through how *RV32I* encoded and know how to implement these instructions in a verilog simulator and possibly in a FPGA board.


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

If we actually classify these instructions based on the encoding scheme, it will be totally 11 classes.

**General Purpose Registers**
It is better to emphasize here that *RV32I* base instruction supports 32 general purpose registers, each has 32 bits length (named as *X0, X1, ....X31*) and one program counter register (*PC*). 
Note, there is no special link register (*LR*) or stack pointer (*SP*), nonetheless, hardware designer often reserve *X1,X2* for *LR, SP*. 
One another thing to note, register *X0* is hardwired to *zero*, you won't store data in *X0*, it is defined as it is to limit the number of instructions in *RV32I* base format.

Quiz: How many bits are needed to address these 32 registers?: Ans: 5.

**Arithmetic Instructions Example**
add X3, X1, X2   // Add data from registers *X1* and *X2*, and store it in register *X3*.

It is encoded as 00000000  rs2 rs1 000 rd 0110011, where rs2, rs1, rd are the 5 bit wide address to the registers *X2,X1* and *X3*.,

sub x3, x1, x2   // Subtract data of register X2 from register X1, and store in register X3

It is encoded as 0100000 rs2 rs1 000 rd 0110011

mul x3, x1, x2   // Multiply the contents of registers X1 and X2, and store  in register x3

It is encoded as 0000001 rs2 rs1 000 rd 0110011

div x3, x1, x2   // Divide the contents of register x1 by register x2, and store in register x3

It is encoded as 0000001 rs2 rs1 100 rd 0110011

rem x3, x1, x2   // Calculate the remainder when the contents of register x1 is divided by register x2, and store the result in register x3

It is encoded as 0000001 rs2 rs1 110 rd 0110011

Encoding itself contains information about what registers we are operating (5bit: 00000 refers to *X0*, 00001 referst to *X1*, and so on).
Lets write these example encoding in abstract variable format *Funct7 rs2 rs1 Funct3 rd Opcode7*,  adding the subscript of two Funct, Opcode (7,3, 7) + 15 (a 3, 5 bit address for register mapping) will get 32. It shows the general Encoding pattern involved in arithmetic operations that load and store data within registers.

An arithmetic operation instruction, a 32 bit length (say bit [31,30,....0]), subfield (sub field bits) [6:0] represents 7 bits wide *opcode*, [11:7] 5 bits wide destination register address, [14:12] a 3 bits wide *funct3* [19:15], [24:20] a two 5 bits wide represents first and second source register address respectively, and [31:25] represents *funct7*.  

**Encoding Scheme**
In *RV32I* instructions set, the encoding scheme is quite regular and it simplifies decoding and execution circuit construction for the hardware designer.
Lets break down the basic encoding scheme and fields in the 32 bit instructions.
&nbsp; **Opcode Field** 7 bits subfield, specifying the general category of the instruction, always reside at 7 LSBs of the instruction.
&nbsp; **Funct3 Field** 3 bits subfield, providing additional information within certain instruction categories (like differentiating between load, store on arithmetic operations).
&nbsp; **Funct7 Field** 7 bits subfield, used for extended arithmetic operations in certain instructions.
&nbsp; **Immediate Field** subfield length varies depending on the instruction (20 bits and 12 bits subfields are the most common one), used for specifing immediate values (constant) in immediate instructions.
&nbsp; **Register Fields** Typically two or three fields of 5 bits wide, addressing one of the 32 general-purpose registers.

Presense of *Funct3, Funct7, Immediate and Register fields* depends on the instruction type. *Opcode field* is always assured to present in the instruction.

**Base Instruction Formats**
There are totally 6 different encoding format presents in *RV32I*, among them 4 are core instruction formats (R/I/S/U) in *RV32I* and two additional formats (B/J), lets list them here.


**R-type** (Register Type)       : format *funct7     rs2   rs1 funct3 rd          opcode* <br />
**I-type** (Immediate Type)      : format *imm[11:0]        rs1 funct3 rd          opcode* <br />
**S-type** (Store Type)          : format *imm[11:5]  rs2   rs1 funct3 imm[4:0]    opcode* <br />
**B-type** (Branch Type)         : format *imm[12|10:5] rs2 rs1 funct3 imm[4:1|11] opcode* <br />
**U-type** (Upper Immediate Type): format *imm[31:12]                  rd          opcode* <br />
**J-type** (Jump Type)           : format *imm[20|10:1|11|19:12]       rd          opcode* <br />


So far, we know rs2, rs1 and rd are Register fields in the encoding scheme, and rs2, rs1 represents second and first register source address, rd represents destination register address.

imm is a variable length subfield bits represent immediate contant value encoded within the instructions. It is 12, 12, 12, 20 and 20 bits wide in *I, S, B, U* and *J* type instructions.


**Opcode** a 7 bits wide subfield always located on 7 bits LSBs of the instructions. In *RV32I* base format opcode[7:0] two LSBs are always *11*, and opcode[4:2] is never equal to *111*. The reason for these encoding constraints are for natural encoding extension schemes for *16, 48, 64, >=192* bits instructions sets defined in *RISC-V*. Note we are only looking after *RV32I* base format.

Opcode Value | represents | meaning, instruction type        |  calculation                 | #variants
---------|---------|-----------------------------------------|------------------------------|----------------
0110111  | *LUI*   |  load up immediate, *U-type*            | reg <- (imm << 12)           | 1
0010111  | *AUIPC* |  add upper immediate to *PC* register   | reg <- PC + (imm << 12)      | 1 
1101111  | *JAL*   |  jump and link, *J-type*                | reg <- PC+4 ; PC <- PC+imm   | 1
1100111  | *JALR*  |  jump and link register, *I-type*       | reg <- PC+4 ; PC <- reg+imm  | 1
1100011  | branch  |  jump and branch Instructions, *B-type* | if(reg OP reg) PC<-PC+imm    | 6
0000011  | load    |  load instructions, *I-type*            | reg <- mem[reg + imm]        | 5
0100011  | store   |  store instructions, *S-type*           | mem[reg+imm] <- reg          | 3
0010011  |  OP     | Immediate Instructions, *I-type*        | reg <- reg OP imm            | 9
0110011  |  OP     | Arithmetic Instructions, *R-type*       | reg <- reg OP reg            | 10
0001111  | FENCE   | memory-ordering for multicores          | skip details now             | 1
1110011  | system  | Instructions EBREAK, ECALL              | skip details now             | 2

Markup : - *LUI* Look up immediate, a *U-Type* instruction to load 20 bits wide constant value into the rd addressed register data.
				- For example, *LUI X5 0x12345*,  it loads the 20 bits MSB of instruction encoding (i.e *imm[31:12] = 0x12345*) into the register *X5* by *X5 <- (imm << 12)*.
				- Instruction Encoding *imm[31:12](=0x12345) rd(=&X5) 0110111*.

		 - *AUIPC* Add upper immediate to *PC*, a *U-Type* instruction to add 20 bits wide constant value with *PC* value, 
				- For example, *AUIPC X5 0x10000*, it adds the 20 bits MSB of *AUIPC* instruction encoding (i.e *imm[31:12] = 0x10000*) with *PC* value and stores it in *X5* register.
				- Instruction Encoding *imm[31:12](=0x10000) rd=(=&X5) 0010111*
		 	
		 - *JAL*: Jump and Link, a *J-type* instruction to add 20 bits signed offset with *PC* register data.
		 		- For example, *JAL X1 offset*, it adds the signed offset value with *PC*
		 - *JALR*: Jump and Link Register, adds an offset 12 bits address with *PC*. 
	
		 - Branch instructions: there are 6 variants on conditional jumps, that depends on a test on two registers

		 - Load and Store Instructions: a 12 bit signed instructions, that loads (*I-type*) and store (*J-type*) correspondingly.

		 - Immediate Instructions: a 12 bit arithmetic operations of *I-type* immediate constant value (from the encoding) with one of the register and store it in another register.

		 - Arithmetic Instructions: operates 32 bit arithmetic operations (pure *R-type*) on register values. 

		 - Fence and Systems: are used to implement memory ordering in multicore systems, and system calls/ebreak respectively.


**Funct3**
**Funct7**
