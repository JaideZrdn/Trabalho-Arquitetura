// ============================================================================
//  shift_left_2 — multiplica por 4 o imediato do desvio
//
//  O campo imediato do beq/bne conta INSTRUCOES, nao bytes. Como cada
//  instrucao ocupa 4 bytes, o valor precisa ser multiplicado por 4 antes de
//  ser somado ao PC+4. Multiplicar por 4 e deslocar 2 casas a esquerda.
//
//      beq em PC=72, imediato +16  ->  76 + (16 << 2) = 76 + 64 = 140 = exit1
//
//  Deslocamento aritmetico nao e necessario: o imediato ja chega estendido
//  com sinal em 32 bits, e deslocar a esquerda preserva o sinal.
// ============================================================================
`timescale 1ns/1ps

module shift_left_2 #(
    parameter DATA_WIDTH = 32
)(
    input  wire [DATA_WIDTH-1:0] in,
    output wire [DATA_WIDTH-1:0] out
);
    assign out = in <<< 2;
endmodule
