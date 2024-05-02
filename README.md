# verilog-riscV32I-machine


*This repo is about Learning  RISC V 32 bit integer base instructions set, making a cook book for the instruction sets and its verilog implementation procedure*

*RISC-V* (say risk-five) is an open source instruction set architecture (*ISA*) based on 
*RISC* (reduced instruction set computing). Here will go through how (and not why) a particular base *RV32I* 
(*RISC-V* 32 bit Integer Instruction set) constructed, so that we will procede to implment verilog instruction simulation circuit. 
We will dicover on why part (well for mostly simplicity and respective hardware implementation) after
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

It is encoded as 00000000  rs2 rs1 000 rd 0110011, where rs2, rs1, rd are the 5 bits wide address to the registers *X2,X1* and *X3*.,

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
Lets break down the basic encoding scheme and fields in the 32 bit instructions. <br />
**Opcode Field** 7 bits subfield, specifying the general category of the instruction, always reside at 7 LSBs of the instruction. <br />
**Funct3 Field** 3 bits subfield, providing additional information within certain instruction categories (like differentiating between load, store on arithmetic operations). <br />
**Funct7 Field** 7 bits subfield, used for extended arithmetic operations in certain instructions. <br />
**Immediate Field** subfield length varies depending on the instruction (20 bits and 12 bits subfields are the most common one), used for specifing immediate values (constant) in immediate instructions. <br />
**Register Fields** Typically two or three fields of 5 bits wide, addressing 32 general-purpose registers. <br />


*Opcode field* is always assured to present in the 7 LSBs bits of a instruction, unlike *Funct3, Funct7, Immediate and Register fields*


**Base Instruction Formats**
There are totally 6 different encoding format presents in *RV32I*, among them 4 are core instruction formats (R/I/S/U) in *RV32I* and two additional formats (B/J), lets list them here.


**R-type** (Register Type)       : format *Funct7     rs2   rs1 Funct3 rd          Opcode* <br />
**I-type** (Immediate Type)      : format *imm[11:0]        rs1 Funct3 rd          Opcode* <br />
**S-type** (Store Type)          : format *imm[11:5]  rs2   rs1 Funct3 imm[4:0]    Opcode* <br />
**B-type** (Branch Type)         : format *imm[12|10:5] rs2 rs1 Funct3 imm[4:1|11] Opcode* <br />
**U-type** (Upper Immediate Type): format *imm[31:12]                  rd          Opcode* <br />
**J-type** (Jump Type)           : format *imm[20|10:1|11|19:12]       rd          Opcode* <br />


So far, we know rs2, rs1 and rd are Register fields in the encoding scheme, and rs2, rs1 represents second and first register source address, rd represents destination register address.

imm is a variable length subfield bits represent immediate contant value encoded within the instructions. It is 12, 12, 12, 20 and 20 bits wide in *I, S, B, U* and *J* type instructions respectively.

As you see, placement of *rs1,rs2, Funct3, Funct7* encoding in the instruction are consistent if it exists in encoding, unlike *immediate field*. 

Now, we structure the irregular *Immediate Field* to make the learning and coding process easier. Lets list the *immediate* field organization in different instruction types. 

Instance Type | Immediate Field Encoding format                                    | Denote it as 
--------------|--------------------------------------------------------------------|---------------
*R-Type*      | Not present                                                        | none
*I-Type*      | 12 bits, sign expansion                                            | *Iimm*
*S-Type*      | 12 bits, sign expansion (stored in two parts)                      | *Simm*
*B-Type*      | 12 bits, sign expansion into upper [31:1] and set 0th bit as zero  | *Bimm*
*U-Type*      | 20 bits, upper [31:12] and set 12 LSB's into zero                  | *Uimm*
*J-Type*	  | 20 bits, sign expansion into upper [31:1] and set 0th bit as zero  | *Jimm*


Lets code them in verilog to create various 32 bits value from *immediate field* of the instruction.
``` verilog
reg [31:0] inst;       // given *RV32I* Instruction, a 32 bit instruction encoding
...
wire [31:0] Iimm = { {21{inst[31]}}, inst[30:20]};                              // if inst is *I-type* instruction
wire [31:0] Simm = { {21{inst[31]}}, inst[30:25], inst[11:7]};                  // if inst is *S-type* instruction
wire [31:0] Bimm = { {20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};   // if inst is *B-type* instruction
wire [31:0] Uimm = { inst[31:12], {12{1'b0}}};                                  // if inst is *U-type* instruction
wire [31:0] Jimm = { {12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0}; // if inst is *J-type* instruction
```


**Opcode** a 7 bits wide subfield always located on 7 bits LSBs of the instructions. In *RV32I* base format opcode[7:0] two LSBs are always *11*, and opcode[4:2] is never equal to *111*. The reason for these encoding constraints are for natural encoding extension schemes for *16, 48, 64, >=192* bits instructions sets defined in *RISC-V*. Note we are only looking after *RV32I* base format.

Opcode Value | represents | meaning, instruction type        |  calculation                 | #variants
---------|---------|-----------------------------------------|------------------------------|----------------
0110111  | *LUI*   |  load up immediate, *U-type*            | reg <- Uimm                  | 1
0010111  | *AUIPC* |add upper immediate to *PC* register,*U* | reg <- PC + Uimm             | 1 
1101111  | *JAL*   |  jump and link, *J-type*                | reg <- PC+4 ; PC <- PC+Jimm  | 1
1100111  | *JALR*  |  jump and link register, *I-type*       | reg <- PC+4 ; PC <- reg+Iimm | 1
1100011  | branch  |  jump and branch Instructions, *B-type* | if(reg OP reg) PC<-PC+Bimm   | 6
0000011  | load    |  load instructions, *I-type*            | reg <- mem[reg + Iimm]       | 5
0100011  | store   |  store instructions, *S-type*           | mem[reg+Simm] <- reg         | 3
0010011  |  OP     | Immediate Instructions, *I-type*        | reg <- reg OP Iimm           | 9
0110011  |  OP     | Arithmetic Instructions, *R-type*       | reg <- reg OP reg            | 10
0001111  | FENCE   | memory-ordering for multicores          | skip details now             | 1
1110011  | system  | Instructions EBREAK, ECALL              | skip details now             | 2

          - *LUI* Look up immediate, a *U-Type* instruction to load 20 bits wide constant value (as *Uimm*) into the rd addressed register data.
				- For example, *LUI X5 0x12345*,  it loads the 20 bits MSB of instruction encoding (i.e *imm[31:12] = 0x12345*) into the register *X5* by *X5 <- (imm << 12)*.
				- Instruction Encoding *imm[31:12](=0x12345) rd(=&X5) 0110111*.

		 - *AUIPC* Add upper immediate to *PC*, a *U-Type* instruction to add 20 bits wide constant value (as *Uimm*) with *PC* value, 
				- For example, *AUIPC X5 0x10000*, it adds the 20 bits MSB of *AUIPC* instruction encoding (i.e *imm[31:12] = 0x10000*) with *PC* value and stores it in *X5* register.
				- Instruction Encoding *imm[31:12](=0x10000) rd(=&X5) 0010111*
		 	
		 - *JAL*: Jump and Link, a *J-type* instruction to add 20 bits signed offset (as *Jimm*) with *PC* register data.
		 		- For example, *JAL X6 offset*, it performs *X6 = PC + 4*, followed by *PC = PC + Jimm* 
				- i.e it store the return address in *X6*, and jump into the target address with relative distance denoted in *Jimm*
				- Instruction Encoding *imm[20|10:1|11|19:12]  rd(=&X6) 1101111*,where *offset* is expanded from *imm* using *Jimm* structure.

		 - *JALR*: Jump and Link Register, to add 12 bits signed offset ( as *Iimm*) with *PC* register data. 
				- For example, *JALR X2 X1, offset*, it performs *X2 = PC + 4*, followed by *PC = X1 + Iimm*
				- i.e it store the return address in *X2*, and then jump to the relative address denoted in *X1 + Iimm*
				- Instruction Encoding *imm[11:0] rs1(=&X1) 000 rd(=&X2) 1100111*, where *offset* is expanded from *imm* using *Iimm* structure.

		 - Branch instructions: there are 6 variants on conditional jumps, that depends on a test on two registers

		 - Load and Store Instructions: loads based on *I-type* immediate constant value extraction 
		 	and store based on *J-type* immediate constant value extraction.

		 - Immediate Instructions: arithmetic operations of *I-type* immediate constant value extraction and two register datas.

		 - Arithmetic Instructions: operates 32 bit arithmetic operations (pure *R-type*) on register datas. 

		 - Fence and Systems: are used to implement memory ordering in multicore systems, and system calls/ebreak respectively.

Lets look into opcode and decide opcode instruction using double equal check statement in verilog code.
```verilog
wire is_alu_reg  = (inst[6:0] == 7'b0110011); // rd <- rs1 OP rs2
wire is_alu_imm  = (inst[6:0] == 7'b0010011); // rd <- rs1 OP Iimm
wire is_load     = (inst[6:0] == 7'b0000011); // rd <- mem[rs1+Iimm]
wire is_store    = (inst[6:0] == 7'b0100011); // mem[rs1+Iimm] <- rd
wire is_branch   = (inst[6:0] == 7'b1100011); // if (rs1 OP rs2) PC <- PC + Bimm
wire is_jalr     = (inst[6:0] == 7'b1100111); // rd <- PC+4; PC<-rs1+Iimm
wire is_jal      = (inst[6:0] == 7'b1101111); // rd <- PC+4; PC <- PC+Jimm
wire is_lui      = (inst[6:0] == 7'b0110111); // rd <- Uimm
wire is_auipc    = (inst[6:0] == 7'b0010111); // rd <- PC + Uimm
wire is_system   = (inst[6:0] == 7'b1110011); // special system call
wire is_fence    = (inst[6:0] == 7'b0001111); // special memory ordering in multicore system
```

Opcode helps us to decide instruction type for execution, additionally *Funct3* and *Funct7* will help us to choose one among existing variant in the respective instruction type. 

**Arithmetic R-Type Instructions**
Arithmetic instruction *R-type*, a most simplest encoding. Here *R-type* arithmetic instructions have 10 variants, they are 
```
ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
```
They are for addition, subtraction, shift left logical, set less than, set less than for unsigned numbers, bitwise *xor*, shift right logical, shift right with sign expansion, bitwise *or* and bitwise *and* operations.

As the *R* instruction encoding *Funct7 rs2 rs1 Funct3 rd Opcode7*, extracting rs1, rs2 and rd registers address as 
```verilog
...
wire [4:0] addr_rs1 = inst[19:15]; // 5 bits wide first register source address
wire [4:0] addr_rs2 = inst[24:20]; // 5 bits wide second register source address
wire [4:0] addr_rd  = inst[11:7];  // 5 bits wide register destination address
...
```
To choose one among 10 variants of arithmetic *R-type* instruction, gather *Funct3, Funct7*

```verilog
wire [2:0] funct3 = inst[14:12]; // 3 bits wide funct3
wire [6:0] funct7 = inst[31:25]; // 7 bits wide funct7
```
Among *funct3*, it will help us to choose 1 among 8 instructions only. But we have 10 *R-Type* arithmetic instructions. The second most significant bit of *funct7* will be used 
to decide a instruction along with *funct3*. Bit 5 of *funct7* encodes *ADD/SUB* and *SRA/SRL*. 

TODO: will implement a sub folder to execute all the variants for *R-type* arithmetic instructions.

**Arithmetic I-Type Instructions**
Arithmetic *I-type*, a second most simplest encoding. Here *I-type* instructions have 9 variants one less than *Arithmetic R-Type*, they are
```
ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
```
If you checked the both these arithmetic sets, there is no *SUBI*, this excluded instruction functionality met by performing *ADDI* with negative Immediate value. In this way, *RISC-V* limits the number of instruction set.

As the *I* instruction, has two registers address and one immediate value.  Recall extracting 12 bit immediate value from 12 MSB bits of instruction as
```verilog
wire [31:0] Iimm={{21{inst[31]}}, inst[30:20]};
```
As you see MSB is the sign of 12 bits intermediate constant, it is appropriately repeated to convert the signed extension of 12 bits immediate value into 32 bits value.

TODO: will implement a sub folder to execute all the variants for *I-type* arithemtetic instructions.

For the sake of completeness lets list all the uncovered instruction type except fence and system instructions *EBREAK, ECALL*.  We will postpone the documentation for system and fence call instead will go for the instruction implementation in *verilog*.

**Store S-type Instructions**
It has 3 variants, they are 
```
SB, SH, SW
```
It represents store byte, store halfword and store word respectively. 

Usage:  *SB X3 Offset(X4)*, adds the 12 bits signed offset value to the register *X4* to point a 32 bit target address, and  store a byte from register memory X3 to the target address. <br />
Similarly *SH X3 Offset(X4)* and *SW X3 Offset(X4)*. 

**Load I-type instructions**
It has 5 variants, they are

```
LB, LBU, LH, LHU, LW
```
It represents load byte, load byte unsigned,  load halfword, load halfword unsigned, and load word respectively.

Usage: *LB X3, Offset(X4)* loads a signed byte from memory to register *X3* with sign-extending it to fill 32 bit register *X3*, the source memory address is calculated by adding 12 bit signed offset value with register *X4*. <br />
Note: this offset is extracted from *immediate field* constant value using *Simm* structure. <br />

Similarly, *LBU X3, Offset(X4)* with zero-extending it to fill the 32 bit register *X3* <br /> 
*LH X3, Offset(X4)* loading 16 bits from memory into register, sign-extending it to fill the 32 bit register *X3*, <br />
*LHU X3 Offset(X4)* loading 16 bits from memory into register, zero-extending it to fill the 32 bit register *X3*,<br /> 
*LW X3 Offset(X4)* loading 16 bits from memory into register, here we dont have to worry about leading signed bit!<br />

**Jump and Branch B-type Instructions**
There are 6 variants of it, they are 
```
BEQ, BNE, BLT, BGE, BLTU, BGEU
```
It represents *branch equal*, *branch not equal*, *branch less than*, *branch greater than or equal*, *branch less than unsinged* and *branch greater than or equal unsigned* respectively.

Usage: *BEQ X1 X2 offset* <br />
*BNE X1 X2 offset* <br />
*BLT X1 X2 offset* <br />
*BGE X1 X2 offset* <br />
*BLTU X1 X2 offset* <br />
*BGEU X1 X2 offset* <br />

In all these instruction it was clear that the instruction evaluating branching is true or not based on the statement and the datas in the register *X1,X2*, for example 
if datas in *X1* and *X2* are equal, then *BEQ* will execute the branching protocol, otherwise, *PC* increments normally and continue its execution process. 

If decided to branch, then we have to compute the target code memory address and load it into the *PC*. 
This is done by simply extracting offset from *immediate field* (by the procedure *Bimm*), and add offset value to *PC* ( i.e relative branching). 
Note for branching, we dont have to save the return address, becuase it is branching not function call or interrupt protocol.

We alreay discussed in some extent the *LUI, AUIPC, JAL* and *JALR*. 
Lets create a subfolder for each instructions type and write *verilog code*. 
Will do in a way that it will reflect the software development process 
instead of a documentation of existing or prepared material!. 
