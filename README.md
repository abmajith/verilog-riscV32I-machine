# verilog-riscV32I-machine

*This repo is about Learning  RISC V 32-bit integer base instructions set,
making a cookbook for the instruction sets and its verilog implementation procedure*

*RISC-V* (say risk-five) is an open-source instruction set architecture (*ISA*)
based on *RISC* (reduced instruction set computer).


The basic philosophy behind *RISC* is
to move the maximum complexity from the silicon to the language compiler (to assembly code writer).
The hardware (development and design) is kept as simple
and fast as possible, i.e. simplify the instruction, lightweight low-power hardware circuit for  
decoding the instruction and execution within the silicon, with the side effects involved 
assembly program development.

*RISC-V* instruction is simple, it is designed to have a limited number
of instructions and the decoding procedure to extract the information.
For example, one can have an instruction *clear* in their instruction set,
to clear one of its general purpose register banks (*reg0*), the same operation can be met by
doing *xor* operation (*reg0 ^ reg0* a logical bitwise exclusive or operation). 
Thus the separate *clear* instruction is no longer required.

Another simplicity in *RISC-V* design is that it simplifies the data access.
It transfers data via only two instructions namely *load* and *store*, all other operations 
are solely performed within the processor.

Here will go through how a particular base *RV32I* *RISC-V* 32-bit Integer Instruction set
constructed, and the *Verilog* code.


This document is created with reference document **The RISC-V Instruction Set Manual, 
Volume I: Unprivileged ISA**
<a href="https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf" class="custom-link">Riscv reference manual</a>.

There are four *RISC-V ISA* base architectures, 
*RV32I*, *RV32E* (embeded version of RV32I for energy constraint), *RV64I*, *RV128I*.

*RV32I* it is a gateway to understand other *RISC-V ISA* bases and extensions. 
All these base instruction sets support integer arithmetic (*and, or, xor, add, sub, shift right, shift left*). 
It does not support floating point arithmetic or integer multiplication/division. 

To include integer multiplication/division capability, we have to include the extension *M* that comprise
details on multiplication/division encoding formats.


*RV32I* Instruction set can be classified into 7 classes (in a simple human-readable way), they are

- **Arithmetic Instructions** like addition, subtraction, and logical bitwise operations.

- **Load and Store Instructions** deals with loading data from memory to register, 
	and store data from register to memory area.

- **Control Transfer Instructions** deal with the flow of the program, they are conditional 
	(think of if else statement operations on register values), unconditional (strict jump), 
	procedure calls and returns. 

- **Data Transfer Instructions** move data within registers or performing operations 
	on data within registers.

- **Immediate Instructions** special type instructions perform on the instruction 
	itself (the part of 32-bit instruction is an operand).

- **Shift Instructions** logical and arithmetic shifts on register data.

- **Comparison Instructions** Comparing register data or register data with immediate 
	value (part of 32-bit instructions field).



If we classify these instructions based on the encoding scheme, 
it will be a total of 6.

**General Purpose Registers**
It is better to emphasize here that *RV32I* base instruction supports 32 general-purpose registers
(named as *X0, X1, ....X31*), each has 32 bits length and one program counter register (*PC*). 

Note, there is no special link register (*LR*) or stack pointer (*SP*), nonetheless, 
hardware designer often reserve *X1,X2* for *LR, SP*. 
And also Note, register *X0* is hardwired to *zero*, 
you won't store data in *X0*, it is defined as it is to limit the number of instructions in *RV32I* 
base format.

Quiz: How many bits are needed to address these 32 registers?: Ans: 5.

Let's introduce these general-purpose registers in Verilog
```verilog
...
reg [31:0] GenRegBanks_X [31:0];  // memory for general purpose registers
reg [31:0] GenReg_PC;             // memory for program counter register
...
```

**Arithmetic Instructions Example**
*ADD X3, X1, X2*   // Add data from registers *X1* and *X2*, and store it in register *X3*. <br />
It is encoded as *0000000  rs2 rs1 000 rd 0110011*, where rs2, rs1, rd are the 5 bits wide 
address to the registers *X2,X1* and *X3*., <br />

*SUB x3, x1, x2*   // Subtracts the value in register *X2* from the value in register X1, 
and store the result in register *X3*. <br />
It is encoded as *0100000 rs2 rs1 000 rd 0110011* <br />


Encoding itself contains information about what registers we are operating 
(5bit: 00000 refers to *X0*, 00001 refers to *X1*, and so on).
Let's write these example encodings in the abstract variable format *Funct7 rs2 rs1 Funct3 rd Opcode7*,  
adding the subscript of two Funct, Opcode (7,3,7) + 15 (a 3, 5-bit address for register mapping) 
will get 32. It shows the general Encoding pattern involved in arithmetic operations that load and store 
data within registers.

An arithmetic operation instruction, a 32-bit length (say bit [31,30,....0]), 
subfield (subfield bits) [6:0] represents 7 bits wide *opcode*, 
[11:7] 5 bits wide destination register address *rd*, [14:12] a 3 bits wide *funct3*, 
[19:15], [24:20] are two 5 bits wide representing the first and second source register 
address *rd1, rd2* respectively, and [31:25] represents *funct7*.

**Encoding Scheme**
In the *RV32I* instructions set, the encoding scheme is quite regular and it simplifies
the decoding and circuit construction for the hardware designer.
Let's break down the basic encoding scheme and fields in the 32-bit instructions.
- **Opcode Field** 7 bits subfield, specifying the general category of the instruction,
	always resides at 7 LSBs of the instruction. <br />

- **Funct3 Field** 3 bits subfield, providing additional information within certain
	instruction categories (like differentiating between load, and store on arithmetic operations).

- **Funct7 Field** 7 bits subfield, used for extended arithmetic operations in certain instructions. <br />

- **Immediate Field** subfield length varies depending on the instruction
	(20 bits and 12 bits subfields are the most common ones), used for specifying 
	immediate values (constant) in immediate instructions.

- **Register Fields** Typically two or three fields of 5 bits wide,
	addressing 32 general-purpose registers.


*Opcode field* is always assured to be present in the 7 LSBs bits of instruction, unlike *Funct3,
Funct7, Immediate, and Register fields*


**Base Instruction Formats**
There are totally 6 different encoding formats present in *RV32I*, 
among them, 4 are core instruction formats (R/I/S/U) in *RV32I* 
and two additional formats (B/J), let's list them here.

Instruction type                 |        -       |   -    |  -    |    -     |       -       |    -
---------------------------------|----------------|--------|-------|----------|---------------|-----------
**R-type** (Register Type)       |  *Funct7*      |  *rs2* | *rs1* | *Funct3* | *rd*          | *Opcode* 
**I-type** (Immediate Type)      |  *imm[11:0]*   |   -    | *rs1* | *Funct3* | *rd*          | *Opcode* 
**S-type** (Store Type)          |  *imm[11:5]*   |  *rs2* | *rs1* | *Funct3* | *imm[4:0]*    | *Opcode* 
**B-type** (Branch Type)         |  *imm[12\10:5]*|  *rs2* | *rs1* | *Funct3* | *imm[4:1\11]* | *Opcode* 
**U-type** (Upper Immediate Type)|  *imm[31:12]*  |    -   |  -    |    -     | *rd*          | *Opcode* 
**J-type** (Jump Type)           |  *imm[20\10:1\11\19:12]*|  -|-  |    -     | *rd*          | *Opcode* 


So far, we know *rs2*, *rs1*, and *rd* are Register fields in the encoding scheme, 
where *rs1*, and *rs2* represent the first and second source register address, and *rd* represents 
destination register address.

imm is a variable length subfield bit representing immediate constant value encoded within the instruction encoding. 
It is 12, 12, 12, 20, and 20 bits wide in *I, S, B, U* and *J* type instructions respectively.

As you see, placement of *rs1,rs2, Funct3, Funct7* encoding in the instruction are consistent 
if it exists in the encoding, unlike the *immediate field*.

Now, we structure the irregular *Immediate Field* to make 
the learning and coding process easier. Let's list the *immediate* 
field organization in different instruction types.  

Instance Type | Immediate Field Encoding format                                    | Denote it as 
--------------|--------------------------------------------------------------------|---------------
*R-Type*      | Not present                                                        | none
*I-Type*      | 12 bits, sign expansion                                            | *Iimm*
*S-Type*      | 12 bits, sign expansion (stored in two parts)                      | *Simm*
*B-Type*      | 12 bits, sign expansion into upper [31:1] and set 0th bit as zero  | *Bimm*
*U-Type*      | 20 bits, into upper [31:12] and set 12 LSBs into zero              | *Uimm*
*J-Type*	    | 20 bits, sign expansion into upper [31:1] and set 0th bit as zero  | *Jimm*


Let's code them in Verilog to create various 32 bits of immediate constant value 
from *immediate field* of the instruction.

```verilog
reg [31:0] inst;       // given *RV32I* Instruction, a 32 bit instruction encoding
...
wire [31:0] Iimm = { {21{inst[31]}}, inst[30:20]};                              // if inst is *I-type* instruction
wire [31:0] Simm = { {21{inst[31]}}, inst[30:25], inst[11:7]};                  // if inst is *S-type* instruction
wire [31:0] Bimm = { {20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};   // if inst is *B-type* instruction
wire [31:0] Uimm = { inst[31:12], {12{1'b0}}};                                  // if inst is *U-type* instruction
wire [31:0] Jimm = { {12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0}; // if inst is *J-type* instruction
// we dont have RImm, as *R-type* instruction don't have immediate field
```


**Opcode** is a 7-bit wide subfield always located on 7-bit LSBs of the instructions. 
In *RV32I* base format opcode[7:0] two LSBs are always *11*, and opcode[4:2] 
is never equal to *111*. These encoding constraints are for natural 
encoding extension schemes for *16, 48, 64, >=192* bits instructions sets and extensions defined by *RISC-V*. 
Note we are only looking after the *RV32I* base format, it does not have MUL, DIV, REM, floating arithmetic, etc...

Opcode Value | represents | meaning, instruction type        |  calculation                 | #variants
---------|---------|-----------------------------------------|------------------------------|----------------
0110111  | *LUI*   |  load up immediate, *U-type*            | reg <- Uimm                  | 1 
0010111  | *AUIPC* |add upper immediate to *PC* register,*U* | reg <- PC + Uimm             | 1 
1101111  | *JAL*   |  jump and link, *J-type*                | reg <- PC+4 ; PC <- PC+Jimm  | 1 
1100111  | *JALR*  |  jump and link register, *I-type*       | reg <- PC+4 ; PC <- reg+Iimm | 1 
1100011  | branch  |  jump and branch Instructions, *B-type* | if(reg OP reg) PC<-PC+Bimm   | 6 
0000011  | load    |  load instructions, *I-type*            | reg <- mem[reg + Iimm]       | 5 
0100011  | store   |  store instructions, *S-type*           | mem[reg+Simm] <- reg         | 3 
0010011  |  OP     | Immediate Instructions, *I-type*        | reg <- reg OP Iimm           | 9 
0110011  |  OP     | Arithmetic Instructions, *R-type*       | reg <- reg OP reg            | 10
0001111  | FENCE   | memory-ordering for multicores          | skip details now             | 1 
1110011  | system  | Instructions EBREAK, ECALL              | skip details now             | 2 


- *LUI* Load upper immediate field, a *U-Type* instruction to load 20 bits wide constant value (as *Uimm*) into 
   the *rd* addressed register data.
	- For example, *LUI X5 0x12345*,  it loads the 20 bits MSB of instruction encoding 
	 (i.e *imm[31:12] = 0x12345*) into the register *X5* by *X5 <- (imm << 12)*. 
    - Instruction Encoding *imm[31:12](=0x12345) rd(=&X5) 0110111*.

- *AUIPC* Add upper immediate to *PC*, a *U-Type* instruction to add 20 bits wide constant value 
   (as *Uimm*) with *PC* value, 
	- For example, *AUIPC X5 0x10000*, it adds the 20 bits MSB of *AUIPC* 
	 instruction encoding (i.e *imm[31:12] = 0x10000*) with *PC* value and stores it in *X5* register.
	- Instruction Encoding *imm[31:12](=0x10000) rd(=&X5) 0010111*
		 	
- *JAL*: Jump and Link, a *J-type* instruction to add 20 bits signed offset 
   (as *Jimm*) with *PC* register data.
	- For example, *JAL X6 offset*, it performs *X6 = PC + 4*, followed by *PC = PC + Jimm* 
	- i.e it store the return address in *X6*, and jump into the target address 
	   with relative *offset* extracted as *Jimm*
	- Instruction Encoding *imm[20|10:1|11|19:12]  rd(=&X6) 1101111*, 
	  where *offset* is expanded from *imm* using *Jimm* structure.

- *JALR*: Jump and Link Register, to add 12 bits signed offset ( as *Iimm*) 
   with *PC* register data. 
	- For example, *JALR X2 X1 offset*, it performs *X2 = PC + 4*, followed by *PC = X1 + Iimm*
	- i.e it store the return address in *X2*, and then jump to the 
	   relative address denoted in *X1 + Iimm*
	- Instruction Encoding *imm[11:0] rs1(=&X1) 000 rd(=&X2) 1100111*, 
	  where *offset* is expanded from *imm* using *Iimm* structure.

- Branch instructions: there are 6 variants on conditional jumps, 
		 		that depends on a test on two registers. Detailed discussion provided down in this document.

- Load and Store Instructions: loads based on *I-type* immediate constant value extraction
      and store based on *J-type* immediate constant value extraction. This immediate field
      acts as *offset* from the memory address stored in the source register.
  - For example, *LW X1 offset(X2)*, it performs loading data from the memory address
    pointed by *X2 + offset* into the register *X1*, more detailed explanation provided down in this document.


- Immediate Instructions: arithmetic operations of *I-type* immediate constant value 
		 	extraction and two register data. Further discussion down in this document

- Arithmetic Instructions: operates 32-bit arithmetic operations (pure *R-type*) 
		 	on register data. Further discussion down in this document.

- Fence and Systems: are used to implement memory ordering in multicore systems, 
		 	and system calls/ebreak respectively.
  - As you gather information from the name, *Fence* is a primitive synchronous mechanism 
    (you might be familiar with this concept if you already dealt with concurrent programming) 
    that ensures safe data write and instruction fetched in and from the memory area 
    in multiteanant or multiprocessor system.
  - System *ecall/ebreak* instruction, on the other hand, is used for software-based system calls or 
    to generate breakpoints in debugging scenarios. 
    When executed, *ebreak* causes the processor to raise an exception, 
    which can be handled by the operating system or a debugging environment.
  - We could skip these two instructions types in this document and *Verilog* development.
    But will revisit after the successful implementation of working *Von Neuman Single Core* design
    for *RV32I*. 

Let's look into opcode and decide opcode instruction using double equal check 
statement in verilog code.
```verilog
...
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
...
```

Opcode helps us to decide on instruction type for execution, additionally *Funct3* and *Funct7*
will help us to choose one among existing variants in the respective instruction type.

**Arithmetic R-Type Instructions**
Arithmetic instruction *R-type*, a most simplest encoding.
Here *R-type* arithmetic instructions have 10 variants, they are
```
ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
```
They are for addition, subtraction, shift left logical, set less than,
set less than for unsigned numbers, bitwise *xor*, shift right logical,
shift right with sign expansion, bitwise *or* and bitwise *and* operations.

As the *R* instruction encoding *Funct7 rs2 rs1 Funct3 rd Opcode7*,
extracting rs1, rs2, and rd registers addresses as 
```verilog
...
wire [4:0] rs1 = inst[19:15]; // 5 bits wide first register source address
wire [4:0] rs2 = inst[24:20]; // 5 bits wide second register source address
wire [4:0] rd  = inst[11:7];  // 5 bits wide register destination address
...
```
To choose one among 10 variants of arithmetic *R-type* instruction by 
gathering *Funct3, Funct7 fields*

```verilog
...
wire [2:0] funct3 = inst[14:12]; // 3 bits wide funct3
wire [6:0] funct7 = inst[31:25]; // 7 bits wide funct7
...
```
Among *funct3*, it will help us to choose 1 among 8 instructions only. 
But we have 10 *R-Type* arithmetic instructions. The second most significant bit of *funct7* will be used 
to decide an instruction along with *funct3*. Bit 5 of *funct7* encodes *ADD/SUB* and *SRA/SRL*. 

Let's list the *arithmetic R-type instructions* usage example here
- ADD X3 X1 X2, adds the value in registers *X1,X2* and store the result in register X3
	- Instruction Encoding: *0000000 rs2(=&X2) rs1(=&X1) 000 rd(=&X3) 0110011*

- SUB X3 X1 X2, substracts the value in register *X2* from the value 
  in register *X1* and stores in register *X3*
	- Instruction Encoding: *0100000 rs2(=&X2) rs1(=&X1) 000 rd(=&X3) 0110011*

- SLL X3 X1 X2, (shift left logical) shifts the value in the register *X1* 
  left by the number of bits specified in register *X2* (only 5 LSBs matters here) and stores in register *X3*
	- Instruction Encoding: *0000000 rs2(=&X2) rs1(=&X1) 001 rd(=&X3) 0110011*

- SLT X3 X1 X2, (set less than) sets the register *X3* to 1 
	if the value in register *X1* is less than the value in register *X2*, otherwise 0
	- Instruction Encoding: *0000000 rs2(=&X2) rs1(=&X1) 010 rd(=&X3) 0110011*

- SLTU X3 X1 X2, (set less than unsigned) sets the register *X3* to 1 if the value 
  in register *X1* is less than the value in register *X2*, otherwise 0
	- Instruction Encoding: *0000000 rs2(=&X2) rs1(=&X1) 011 rd(=&X3) 0110011*

- XOR X3 X1 X2, (bitwise *xor*) sets the register *X3* 
  the result of *xor* operation on the value of registers *X1,X2*.
	- Instruction Encoding: *0000000 rs2(=&X2) rs1(=&X1) 100 rd(=&X3) 0110011*

- SRL X3 X1 X2, (shift right logical) shifts the value in the register *X1* 
	by the number of bits specified in register *X2* (only 5 LSBs matters here) 
	and stores in register *X3*, by doing right shift logical, 
	it will fill the leading values by zero i.e zero-fill
	- Instruction Encoding: *0000000 rs2(=&X2) rs1(=&X1) 101 rd(=&X3) 0110011*

- SRA X3 X1 X2, (shift right arithmetic) shifts the value in the register 
	*X1* by the number of bits specified in register *X2* (only 5 LSBs matters here) 
	and stores in register *X3*, by doing right shift arithmetic, 
	it will fill the leading values by signed value i.e *X1[31]* msb of *X1* value.
	- Instruction Encoding: *0100000 rs2(=&X2) rs1(=&X1) 101 rd(=&X3) 0110011*

- OR X3 X1 X2, (bitwise *or*) sets the register *X3* the result of *or* 
	operation on the value of registers *X1, X2*.
	- Instruction Encoding: *0000000 rs2(=&X2) rs1(=&X1) 110 rd(=&X3) 0110011*

- AND X3 X1 X2, (bitwise *and*) sets the register *X3* the result of *and* 
	operation on the value of registers *X1, X2*.
	- Instruction Encoding: *0000000 rs2(=&X2) rs1(=&X1) 111 rd(=&X3) 0110011*

As mentioned earlier *opcode* is the same for all the *arithmetic R-type instruction*.
*funct3* code is same for *SRL,SRA*, it is distinquished by the *funct7* code, 
change in bit number 5. Similarly, the *funct3* code is the same for *ADD, SUB*, 
it is distinguished by the *funct7* code, changed in bit number 5. 

So, the *funct7* code is almost constant (*0000000*), except for two 
instructions (*SUB, SRA* with *0100000*). Let's write a Verilog code to do *arithmetic R-type instructions* 
based on *case endcase* statement on *funct3,funct7*
```verilog
reg [31:0] op1; // reg for fetching first source register value
reg [31:0] op2; // reg for fetching second source register value
...
op1 = GenRegBanks_X[rs1];  // fetching first source register value
op2 = GenRegBanks_X[rs2];  // fetching second source register value
...
reg [31:0] result; // local reg for storing the arithmetic R-type instruction result
...
case(funct3)
	3'b000: result = (funt7[5]) ? (op1 - op2) : (op1+op2);                          // addition or subtraction
	3'b001: result = (op1 << op2[4:0]);                                             // left shift logical
	3'b010: result = ($signed(op1) < $signed(op2));                                 // signed less than
	3'b011: result = (op1 < op2);                                                   // unsigned less than
	3'b100: result = (op1 ^ op2);                                                   // bitwise xor
	3'b101: result = (funct7[5]) ? ($signed(op1) >>> op2[4:0]) : (op1 >> op2[4:0]);  // shift right logical or arithmetic 
	3'b101: result = (op1 | op2);					                                  // bitwise or
	3'b111: result = (op1 & op2);						                              // bitwise and 
endcase
...
GenRegBanks_X[rd] <= result;  // transfering the computed local result to the destination register
...

```

**Arithmetic I-Type Instructions**
Arithmetic *I-type*, the second most simplest encoding. Here *I-type* instructions have 
9 variants one less than *Arithmetic R-Type*, they are
```
ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
```
It represents, addition immediate, set less than immediate, 
set less than immediate unsigned, *xor* immediate, *or* immediate, 
*and* immediate, shift left logical immediate, shift right logical immediate, 
shift right arithmetic immediate.

If you check these arithmetic immediate instruction sets (*I-type*) with arithmetic 
instruction register sets (*R-type*), there is no *SUBI*, this excluded instruction 
functionality is met by performing *ADDI* with negative Immediate value. 
In this way, *RISC-V* limits the number of instruction sets.

The *I* instruction has two register addresses and one immediate value.  
Recall extracting 12-bit immediate value from 12 MSB bits of instruction as
```verilog
wire [31:0] Iimm={{21{inst[31]}}, inst[30:20]};
```
As you see MSB is the sign of 12 bits *immediate* constant, 
it is appropriately repeated for the signed extension of 12 bits immediate 
value into 32-bit value.

Here, we are not listing the *arithmetic I-type* instruction and verilog operations in detail, 
since it is almost the same procedure as *arithmetic R-type* instructions, 
The only difference is, that there is no second source register address *rs2* and hence no second operand, 
instead, we have *Iimm* (a signed extension of the immediate field) as the second operand.

But wait a minute, we have 9 variants in this type, and we don't have *funct7*,
how exactly do we choose the correct instruction for execution by just using *funct3*? <br />
Ans: Let's go back and read *arithmetic I-type instructions*, now we know that only
overlapping can happen for *SRLI, SRAI* when *funct3==101*. So?
Recall one more information, for doing shift operations in a 32-bit instruction register, we need only 5 LSBs of immediate field,
the remaining 7 bits can be used efficiently,
when the compiler or assembler produces such code, it uses this space
to inform the hardware to choose either *SRLI* or *SRAI*.  <br />
It is an important point to remember when creating the respective *Verilog* module, 
as it happens to me, I spend a lot of time debugging the *SRA* immediate instruction (code in the subfolder *RV32I_VonNeumanArch*). <br />


*RISC-V* has specification for this operation, 
if imm[10]th bit (i.e instruction 30th bit) is zero 
it has to perform *SRLI* otherwise it has to perform *SRAI*. 


**Load and Store Instructions**
*RV32I* is 32-bit address space that is byte-addressed, (i.e a 32-bit address will point to a byte memory). 
In *RV32I*, all the arithmetic instructions only operates on CPU registers(*X0 to X31, PC*), 
it never perform computation directly on the memory data. It loads data from memory, perform some computation
 within the registers and safely write back to the memory. 

-**Store S-type Instructions**
It has 3 variants, they are 
```
SB, SH, SW
```
It represents *store byte*, *store halfword*, and *store word* respectively.  <br />

*Byte* store instruction: *SB rs2 Offset(rs1)*, target memory address computed by adding 
the 12-bit signed offset value (from the immediate field in *S* instruction) to the 
register and store the*least significant register byte* from register address *rs2* to the target address. <br />

*Halfword* store instruction *SH rs2 Offset(rs1)* stores two *least significant register byte* from the register address *rs2* 
to the memory address *m,m+1*, where *m* is address, computed by adding 
12-bit signed offset value (from immediate field) to the value in register address *rs1*, 
the order in which these two bytes stored in memory address *m,m+1* depends on the 
*endian* configuration. 
For example in *little-endian* configuration, *least significant register byte* stored in memory *m* and 
the second *least significant register byte* stored in memory *m+1* <br />

*Word* store instruction *SW rs2 Offset(rs1)* stores value from register address *rs2* 
to the memory address *m,m+1,m+2,m+3*, where *m* calcuated as before. <br />

*Verilog* code snippet (for little-endieness format) will be

```verilog
reg [31:0] op1; // reg for fetching first source register value
reg [31:0] op2; // reg for fetching second source register value
reg [31:0] memAddr; // reg for storing the save memory address
// Simm holds the immediate offset value
...
reg [7:0] RW_MEM[START_ADDRESS:START_ADDRESS+NUM_BYTE_MEM_BLOCKS-1]; // a block of read-write memory
...
op1 = GenRegBanks_X[rs1];  // fetching first source register value
op2 = GenRegBanks_X[rs2];  // fetching second source register value
memAddr = op2 + Simm;
...
RW_MEM[memAddr+0] <= op1[7:0];                                     // storing a least significant (LS) byte
RW_MEM[memAddr+1] <= (funct3[0]) ? op1[15:8]  : RW_MEM[memAddr+1]; // based on *funct3* storing second LS byte
RW_MEM[memAddr+2] <= (funct3[1]) ? op1[23:16] : RW_MEM[memAddr+2]; // for storing a word based on *funct3*
RW_MEM[memAddr+3] <= (funct3[1]) ? op1[31:24] : RW_MEM[memAddr+3]; // for storing a word based on *funct3*
```

-**Load I-type instructions**
It has 5 variants, which are

```
LB, LBU, LH, LHU, LW
```
It represents *load byte*, *load byte unsigned*, *load halfword*, 
*load halfword unsigned*, and *load word* respectively. <br />

*Byte* load instruction: *LB rd, Offset(rs1)* loads a signed byte from memory to register address *rd* 
with sign-extending it to fill leading bit values in the register address *rd*, the source memory address 
is calculated by adding a 12-bit signed offset value (from immediate field in *I* instruction) 
with value in register address *rs1*. <br />
*Byte unsigned* load instruction: *LBU rd, Offset(rs1)* same as before, except, leading bits are filled with zero. <br /> 
*Halfword* load instruction: *LH rd, Offset(rs1)* loading 2 bytes from memory *m,m+1* into a register, sign-extending it to fill 
the leading bits value in register address *rd*, memory address *m* is computed by adding *Offset* value with the value in register address *rs1* <br />
*Halfword unsigned* load instruction: *LHU rd Offset(rs1)* same as *LH* except, zero-filling in the lead bits value in register address *rd*,<br /> 
*LW rd Offset(rs1)* loading 4 bytes from memory *m,m+1,m+2,m+3* into register address *rd*, *m* is computed as before, 
here we do not have to worry about leading signed bit!<br />

*Verilog* code snippet (for little-endieness format) will be
```verilog
reg [31:0] op1; // reg for fetching first source register value
reg [31:0] memAddr; // reg for storing the load memory address
// Iimm holds the immediate offset value
...
reg [7:0] MEM[START_ADDRESS:START_ADDRESS+NUM_BYTE_MEM_BLOCKS-1]; // a block of read or read-write memory
...
op1 = GenRegBanks_X[rs1];  // fetching first source register value
memAddr = op1 + Iimm;

case(funct3)
  3'b000 : GenRegBanks_X[rd] <= {{24{MEM[memAddr][7]}}, MEM[memAddr]};                          // for loading a byte
  3'b100 : GenRegBanks_X[rd] <= {{24{1'b0}}, MEM[memAddr]};                                     // for loading a unsigned byte
  3'b001 : GenRegBanks_X[rd] <= {{16{MEM[memAddr+1][7]}}, MEM[memAddr+1], MEM[memAddr]};        // for loading half word
  3'b101 : GenRegBanks_X[rd] <= {{16{1'b0}}, MEM[memAddr+1], MEM[memAddr]};                     // for loading unsigned half word
  3'b010 : GenRegBanks_X[rd] <= {MEM[memAddr+3], MEM[memAddr+2], MEM[memAddr+1], MEM[memAddr]}; // for loading a full word
endcase
```


**Jump and Branch B-type Instructions**
There are 6 variants of it, they are 
```
BEQ, BNE, BLT, BGE, BLTU, BGEU
```
It represents *branch equal*, *branch not equal*, *branch less than*, 
*branch greater than or equal*, *branch less than unsinged* and 
*branch greater than or equal unsigned* respectively.

Usage: *BEQ X1 X2 offset* <br />
*BNE X1 X2 offset* <br />
*BLT X1 X2 offset* <br />
*BGE X1 X2 offset* <br />
*BLTU X1 X2 offset* <br />
*BGEU X1 X2 offset* <br />


In all these instructions it was clear that the instruction 
evaluating branching is true or not based on the statement and 
the data values in the register *X1,X2*, for example 
if data in *X1* and *X2* are equal, then *BEQ* will execute 
the branching protocol, otherwise, *PC* increments normally 
and continue its execution process. 

If it decides to do a branch, it first computes the target 
memory code address and loads it into the *PC*. This is done by
extracting offset from *immediate field* (by the procedure *Bimm*), 
and adding an offset value to *PC* (i.e. relative branching). Note for branching, 
it does not want to save the return address, because it is 
branching not function call or interrupt protocol.

*Verilog* code snippet will be
```verilog
...
reg [31:0] op1; // reg for fetching first source register value
reg [31:0] op2; // reg for fetching second source register value
// Bimm an extracted immediate field value
reg [31:0] nextPC; // reg for commputing next program counter value
// GenReg_PC is the program counter value
...
op1 = GenRegBanks_X[rs1];  // fetching first source register value
op2 = GenRegBanks_X[rs2];  // fetching second source register value
...
reg do_branch; // register for checking the branc condition
case(funct3)
3'b000:  do_branch = (op1 == op2);                   // branch on equal
3'b001:  do_branch = (op1 != op2);                   // branch on not equal
3'b100:  do_branch = ($signed(op1) < $signed(op2));  // branch on less than
3'b101:  do_branch = ($signed(op1) >= $signed(op2)); // branch on greater than or equal to
3'b110:  do_branch = (op1 < op2);                    // branch on less than, unsigned version
3'b111:  do_branch = (op1 >= op2);                   // branch on greather than or equal to unsigned version
default: do_branch = 1'b0;                           // default, dont do branch
endcase
...
always @(*) begin
  if (is_branch && do_branch) begin // if it is branch instruction execution and decided to do branch then
    nextPC = GenReg_PC + Bimm; // always relative branch
  end else begin
    nextPC = GenReg_PC+4; // 32-bit instruction, need 4 bytes to move for the next instruction
  end
end
...
```

We already discussed to an extent the *LUI, AUIPC, JAL*, and *JALR*. 
We will move to create a subfolder for each instruction type and write *verilog code*. 
Will do it in a way that will reflect the software development process 
instead of documentation of existing or prepared material! 

```verilog
// for LUI instruction
GenRegBanks_X[rd] = Uimm;

// for AUIPC
GenRegBanks_X[rd] = Uimm + GenReg_PC;

// for JAL
GenRegBanks_X[rd] = GenReg_PC + 4; // safely storing the next instruction address into the destination register address
nextPC = GenReg_PC + Jimm;

// for JALR 
GenRegBanks_X[rd] = GenReg_PC + 4; // safely storing the next instruction address into the destination register address
nextPC = GenReg_PC + Iimm; 
// recall the differnce, JAL for jumping 20 bit offset address
// JALR for jumping 12 bit offset address, both are relative jumping.
```

**Winding Up**
We acquired that in *RV32I* (or any other base instruction set from *RISC-V*), the
load and store are the only two instructions that move data between memory and processor.
All other instructions are solely executed within the processor. 
To move ahead and implement *RV32I*, it is better to have an eagle view of 
the single-core processor and memory architecture. If we were familiar with this architecture, 
we could start the *verilog RTL* (Register Transfer Level) design for the *processor*.  

Let's take an eagle-eye view of a single-core processor architecture in the context of the *RV32I* 
base instruction set of the *RISC-V ISA*, along with the memory architecture:

**Processor Core:**
- The processor core contains components such as the instruction fetch unit 
(to grab the instruction from the code block), 
instruction decode unit, execution units (like *ALU* arithmetic logic unit, load/store data, branching,etc), 
register bank, and the control logic.

- Instructions are fetched from memory, decoded, and executed within the processor core.

**Memory Architecture**
- The memory architecture includes different types of memory:    
- Instruction Memory block: a read-only memory area, that stores the program instructions.    
- Data Memory block: a read-and-write data memory area, to work on the program instructions
- Both instruction and data memories are accessed using the memory address generated by the processor.

**Address and Data buses**    
- The processor communicates with memory address and data buses.    
- The address bus carries memory addresses generated by the processor to 
  select specific locations in memory.    
- The data bus carries data between the processor and memory. 
Data is read from memory into the processor or written from the processor into memory.

**Control Signals**       
- Control signals are generated by the processor to coordinate memory access 
	(like selecting read or write data into memory, or read the instruction) and other operations.      
- Control signals include read/write signals to indicate the direction of data transfer, 
  chip select signals to select the memory device to begin accessing and 
	other signals for synchronization and timing purposes.


It is a lot to digest, it is important to have a global computing architecture and working principle
to organize our thoughts and develop organized software.
For a detailed picture and discussion about processors and their architecture 
refer to intellectual academic journals and open-source material.

I wrote a short description about a single core Von-Neuman architecture a much simpler architecture to realize
for *RISC-V* type instruction on the page 
<a href="https://github.com/abmajith/verilog-riscV32I-machine/tree/main/RV32I_VonNeumanArch" 
 		class="custom-link">Executing RV32I in Von-Neuman Architecture with Verilog module and test bench</a>
(*Von Neuman*, pronounced as F'n-Noy-mon). 
