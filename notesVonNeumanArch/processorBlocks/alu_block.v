module IV32IALU
  (
  // there are two operands
  input wire [31:0] op_a,
  input wire [31:0] op_b,
  // funct3 code
  input wire [2:0]  funct3,
  // sign bit to perform add/sub or logical/arithmetic right shift
  input wire        op_sign,
  // some additional aritmetic results
  output wire zero,
  output wire negative,
  output reg overflow,
  output reg [31:0] result
  );
  
  // internal signals
  wire [31:0] sum;
  wire [32:0] minus;
  wire        LT;
  wire        LTU;
  wire [4:0]  shamt;

  // if subtract use one's complement and add one otherwise normal sum
  assign sum      = op_a + op_b;
  assign minus    = {1'b0, op_a} + {1'b1, ~op_b} + 33'b1;
  assign zero     = (|result) ? 1'b0 : 1'b1; // if the result is zero, set the zero wire
  assign negative = result[31];
  assign LT       = (op_a[31] ^ op_b[31]) ? op_a[31] : minus[32];
  assign LTU      = minus[32];
  assign shamt    = op_b[4:0];
  
  
  always @(*) begin
    overflow  = (op_sign)  ? ((op_a[31] ^ op_b[31]) & (op_a[31] ^ minus[31])) : 
                              ~(op_a[31] ^ op_b[31]) & (op_a[31] ^ sum[31]);
  end

  always @ (*) begin
    case(funct3)
      // subtraction/addition
      3'b000: result = (op_sign) ? minus[31:0] : sum;
      // sll
      3'b001: result = (op_a << shamt);
      // slt
      3'b010: result = {31'b0, LT};
      // sltu
      3'b011: result = {31'b0,LTU};
      // xor
      3'b100: result = (op_a ^ op_b);

      // sra/srl
      3'b101: result = (op_sign) ? ($signed(op_a) >>> shamt) : ($signed(op_a) >> shamt); 

      // or
      3'b110: result = (op_a | op_b);
      // and
      3'b111: result = (op_a & op_b);

      default: result = 32'b0;

    endcase
  end

endmodule
