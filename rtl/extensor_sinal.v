// ============================================================================
//  extensor_sinal
//
//  OBJETIVO
//  Esticar um numero de LARGURA_ENTRADA bits para LARGURA_SAIDA bits SEM
//  mudar o valor que ele representa — inclusive quando o valor e negativo.
//
//  POR QUE O PROCESSADOR PRECISA DISSO
//  O campo imediato das instrucoes de formato I tem 16 bits. A ALU opera em
//  32. Alguem precisa fazer a ponte, e nao basta preencher com zero:
//
//      addi $sp, $sp, -20
//          imediato, 16 bits:       1111111111101100
//          preenchido com ZERO:     00000000000000001111111111101100  = 65516  ERRADO
//          preenchido com o SINAL:  11111111111111111111111111101100  = -20    certo
//
//  A regra do complemento de dois e essa: para esticar preservando o valor,
//  repete-se o bit mais significativo (o bit de sinal) nas casas novas.
//
//  TIPO DE BLOCO
//  Combinacional. Nao tem clock, nao guarda estado. A saida acompanha a
//  entrada continuamente — e um pedaco de fiacao com logica, nao um registrador.
// ============================================================================
`timescale 1ns/1ps

module extensor_sinal #(
    parameter LARGURA_ENTRADA = 16,
    parameter LARGURA_SAIDA   = 32
)(
    input  wire [LARGURA_ENTRADA-1:0] entrada,
    output wire [LARGURA_SAIDA-1:0]   saida
);

    // posicao do bit de sinal: o mais significativo da entrada
    localparam BIT_SINAL = LARGURA_ENTRADA - 1;

    // quantos bits precisam ser criados para chegar na largura de saida
    localparam N_EXTRA = LARGURA_SAIDA - LARGURA_ENTRADA;

    // As duas chaves tem papeis DIFERENTES, e e aqui que todo mundo se perde:
    //
    //     {N_EXTRA{ entrada[BIT_SINAL] }}   chave de REPLICACAO:
    //                                       repete aquele 1 bit N_EXTRA vezes
    //
    //     { ......... , entrada }           chave de CONCATENACAO:
    //                                       gruda os bits novos na frente
    //
    // Resultado: N_EXTRA copias do bit de sinal, seguidas da entrada inteira.
    assign saida = {{N_EXTRA{entrada[BIT_SINAL]}}, entrada};

endmodule
