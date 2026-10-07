// ============================================================================
//  alu_control — decide a operacao da ALU
//
//  Recebe alu_op (da unidade de controle) e o campo funct (da instrucao).
//  Existe para que a unidade de controle principal nao precise conhecer os
//  codigos funct: ela so diz "e aritmetica de endereco", "e subtracao de
//  desvio" ou "olhe o funct", e este modulo resolve o resto.
//
//      alu_op = 00  ->  ADD   (lw, sw, addi)
//      alu_op = 01  ->  SUB   (beq, bne)
//      alu_op = 10  ->  olhar o campo funct (instrucoes de formato R)
//      alu_op = 11  ->  SLT   (slti)
// ============================================================================
`timescale 1ns/1ps

module alu_control #(
    parameter FUNCT_WIDTH = 6,
    parameter CTRL_WIDTH  = 4,
    parameter ALUOP_WIDTH = 2
)(
    input  wire [ALUOP_WIDTH-1:0] alu_op,
    input  wire [FUNCT_WIDTH-1:0] funct,
    output reg  [CTRL_WIDTH-1:0]  alu_control
);
    localparam OP_AND = 4'b0000, OP_OR  = 4'b0001, OP_ADD = 4'b0010,
               OP_SUB = 4'b0110, OP_SLT = 4'b0111, OP_SLL = 4'b1000;

    // campos funct usados pelo programa de teste
    localparam F_ADD = 6'h20, F_SUB = 6'h22, F_AND = 6'h24,
               F_OR  = 6'h25, F_SLT = 6'h2a, F_SLL = 6'h00;

    always @(*) begin
        case (alu_op)
            2'b00: alu_control = OP_ADD;   // calculo de endereco e addi
            2'b01: alu_control = OP_SUB;   // comparacao de beq/bne
            2'b11: alu_control = OP_SLT;   // slti
            2'b10: begin                   // formato R: o funct decide
                case (funct)
                    F_ADD: alu_control = OP_ADD;
                    F_SUB: alu_control = OP_SUB;
                    F_AND: alu_control = OP_AND;
                    F_OR:  alu_control = OP_OR;
                    F_SLT: alu_control = OP_SLT;
                    F_SLL: alu_control = OP_SLL;
                    default: alu_control = OP_ADD;   // jr nao usa a ALU
                endcase
            end
            default: alu_control = OP_ADD;
        endcase
    end
endmodule
