typedef enum logic [3:0] {
    ALL_ADD = 4'b0000,
    ALL_SUB = 4'b0001,
    ALL_AND = 4'b0010,
    ALL_OR  = 4'b0011,
    ALL_XOR = 4'b0100,
    ALL_SLL = 4'b0101,
    ALL_SRL = 4'b0110,
    ALL_SRA = 4'b0111,
    ALL_SLT = 4'b1000,
    ALL_SLTU = 4'b1001,
} alu_op_t;

module alu (
    input logic [31:0] a,
    input logic [31:0] b,
    input logic alu_op_t op, 
    output logic [31:0] result,
    output logic zero
);

    always_comb begin
        case (op)
            ALL_ADD: result = a + b;                                    // ADD, ADDI, Load/Store instructions
            ALL_SUB: result = a - b;                                    // SUB
            ALL_AND: result = a & b;                                    // AND, ANDI
            ALL_OR:  result = a | b;                                    // OR, ORI
            ALL_XOR: result = a ^ b;                                    // XOR, XORI    
            ALL_SLL: result = a << b[4:0];                              // SLL, SLLI
            ALL_SRL: result = a >> b[4:0];                              // SRL, SRLI
            ALL_SRA: result = $signed(a) >>> b[4:0];                    // SRA, SRAI
            ALL_SLT: result = $signed(a) < $signed(b) ? 32'b1 : 32'b0;  // SLT, SLTI
            ALL_SLTU: result = a < b ? 32'b1 : 32'b0;                   // SLTU, SLTIU
            default: result = 32'b0;
        endcase
        zero = (result == 32'b0);
    end

endmodule