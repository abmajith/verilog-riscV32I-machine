module IV32IBranch (
  // control unit to execute branch unit
  input wire br_execute,
  // there are two operands
  input wire [31:0] op_a,
  input wire [31:0] op_b,
  // funct3 code
  input wire [2:0] funct3,
  output reg do_branch
  );
  
  // internal signals
  wire [32:0] minus;
  wire        LT;
  wire        LTU;
  wire        EQ;
  

  // these common set up reduce the hardware area
  assign minus    = {1'b0, op_a} + {1'b1, ~op_b} + 33'b1;
  assign LT       = (op_a[31] ^ op_b[31]) ? op_a[31] : minus[32];
  assign LTU      = minus[32];
  assign EQ       = (minus[31:0] == 0);

  always @(*) begin
    if (br_execute) begin
      case(funct3)
        3'b000:  do_branch = EQ; // BEQ
        3'b001:  do_branch = !EQ; // BNE
        3'b100:  do_branch = LT; // BLT
        3'b101:  do_branch = !LT; // BGE
        3'b110:  do_branch = LTU; // BLTU
        3'b111:  do_branch = !LTU; // BGEU
        default: do_branch = 1'b0; // default dont do branch
      endcase
    end else begin
      do_branch = 1'b0; // by default dont do branch
    end
  end

endmodule
