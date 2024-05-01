

reg [31:0] inst; // a 32 bit instruction encoding
...
wire is_alu_reg  = (inst[6:0] == 7'b0110011); // rd <- rs1 OP rs2
wire is_alu_imm  = (inst[6:0] == 7'b0010011); // rd <- rs1 OP Iimm[11:0]
wire is_load     = (inst[6:0] == 7'b0000011); // rd <- mem[rs1+Iimm[11:0]]
wire is_store    = (inst[6:0] == 7'b0100011); // mem[rs1+Iimm[11:0]] <- rd
wire is_branch   = (inst[6:0] == 7'b1100011); // if (rs1 OP rs2) PC <- PC + {Bimm[12:1],0}
wire is_jalr     = (inst[6:0] == 7'b1100111); // rd <- PC+4; PC<-rs1+Iimm[11:0]
wire is_jal      = (inst[6:0] == 7'b1101111); // rd <- PC+4; PC <- PC+{Jimm[20:1],0}
wire is_lui      = (inst[6:0] == 7'b0110111); // rd <- Uimm[31:12] << 12
wire is_auipc    = (inst[6:0] == 7'b0010111); // rd <- PC + (Uimm[31:12] << 12)
wire is_system   = (inst[6:0] == 7'b1110011); // special system call
wire is_fence    = (inst[6:0] == 7'b0001111); // special memory ordering in multicore system
