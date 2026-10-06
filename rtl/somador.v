// ============================================================================
//  somador — somador combinacional de dois valores
//
//  OBJETIVO
//  Somar dois numeros de LARGURA bits. Simples assim: nao tem clock, nao tem
//  sinal de controle, nao escolhe operacao. So soma.
//
//  ONDE ELE E USADO — DUAS VEZES NO DATAPATH
//
//  1) somador de PC+4:  a = endereco_atual (do pc)
//                       b = 4
//                     soma = endereco da proxima instrucao
//
//  2) somador de desvio: a = pc_plus_4
//                        b = imediato estendido deslocado 2 bits a esquerda
//                      soma = destino do beq/bne quando o desvio e tomado
//
//  Sao duas INSTANCIAS do mesmo modulo, nao dois modulos diferentes. E tambem
//  o motivo de este somador ser separado da ALU: no monociclo os tres calculos
//  (PC+4, destino do desvio, e a operacao da instrucao) acontecem no MESMO
//  ciclo, entao precisam de hardware separado. Nao da para reaproveitar a ALU.
// ============================================================================
`timescale 1ns/1ps

module somador #(
    parameter LARGURA = 32
)(
    input  wire [LARGURA-1:0] a,
    input  wire [LARGURA-1:0] b,
    output wire [LARGURA-1:0] soma
);

    assign soma = a + b;

    // O estouro (overflow) e ignorado de proposito: enderecos de instrucao
    // circulam dentro da faixa do programa e o MIPS usa aritmetica sem sinal
    // para calculo de endereco. Quem precisa detectar overflow e a ALU, nao
    // este somador.

endmodule
