// ============================================================================
//  alu — unidade logica e aritmetica
//
//  Executa a operacao selecionada por alu_control sobre as duas entradas.
//  O sinal `zero` e o que o beq/bne usam para decidir o desvio: como esses
//  desvios sao implementados com uma SUBTRACAO, zero = 1 significa que os dois
//  operandos sao iguais.
//
//  O deslocamento do sll e `b << a`: o mux_alu_a coloca o shamt na entrada A
//  e o mux_alu_b deixa o valor do registrador na entrada B.
// ============================================================================
`timescale 1ns/1ps

module alu #(
    parameter DATA_WIDTH = 32,
    parameter CTRL_WIDTH = 4
)(
    input  wire [DATA_WIDTH-1:0] a,
    input  wire [DATA_WIDTH-1:0] b,
    input  wire [CTRL_WIDTH-1:0] alu_control,
    output reg  [DATA_WIDTH-1:0] result,
    output wire                  zero
);
    // codificacao das operacoes (mesma usada pelo alu_control)
    localparam OP_AND = 4'b0000,
               OP_OR  = 4'b0001,
               OP_ADD = 4'b0010,
               OP_SUB = 4'b0110,
               OP_SLT = 4'b0111,
               OP_SLL = 4'b1000;

    always @(*) begin
        case (alu_control)
            OP_AND: result = a & b;
            OP_OR:  result = a | b;
            OP_ADD: result = a + b;
            OP_SUB: result = a - b;
            // comparacao COM SINAL: slt/slti operam sobre inteiros com sinal
            OP_SLT: result = ($signed(a) < $signed(b)) ? {{(DATA_WIDTH-1){1'b0}}, 1'b1}
                                                       : {DATA_WIDTH{1'b0}};
            // sll: desloca B pela quantidade em A (A traz o shamt)
            OP_SLL: result = b << a[4:0];
            default: result = {DATA_WIDTH{1'b0}};
        endcase
    end

    assign zero = (result == {DATA_WIDTH{1'b0}});
endmodule
