// ============================================================================
//  memoria_dados — onde o programa guarda variaveis
//
//  OBJETIVO
//  Atender as instrucoes lw (ler uma palavra) e sw (escrever uma palavra).
//  E a unica memoria que o programa modifica durante a execucao.
//
//  O QUE MORA AQUI, no programa de teste:
//      palavras   0 a   7   ->  o vetor v[] = {5,3,8,1,9,2,7,4}
//      palavras 251 a 255   ->  a pilha ($ra, $s0, $s1, $s2, $s3 salvos pelo sort)
//
//  POR QUE PROFUNDIDADE = 256
//  O main inicializa $sp = 1024, que e a palavra 255. A pilha cresce para
//  baixo e o unico quadro usado vai ate a palavra 251. O endereco de dados
//  mais alto que o programa toca e 1020. Com 256 palavras (indices 0 a 255)
//  cabe exatamente, e ainda sobram 243 palavras livres entre o topo do vetor
//  e a base da pilha. Memoria menor faz a pilha colidir com o vetor e o
//  programa ordena errado sem dar erro nenhum.
//
//  LEITURA E ESCRITA, DE NOVO COM NATUREZAS DIFERENTES
//  - Leitura combinacional: o lw precisa do dado ainda dentro do ciclo, para
//    gravar no banco de registradores no fim dele.
//  - Escrita sequencial: o sw so grava na subida do clock.
// ============================================================================
`timescale 1ns/1ps

module memoria_dados #(
    parameter LARGURA      = 32,
    parameter PROFUNDIDADE = 256
)(
    input  wire                clk,
    input  wire                escreve_mem,    // 1 durante um sw
    input  wire [LARGURA-1:0]  endereco,       // calculado pela ALU, em bytes
    input  wire [LARGURA-1:0]  dado_escrita,   // valor de rt, para o sw
    output wire [LARGURA-1:0]  dado_leitura,   // valor lido, para o lw
    // porta de leitura independente, so para observacao externa (displays da
    // FPGA). Nao interfere no processador: e um segundo ponto de leitura do
    // mesmo array, com endereco proprio.
    input  wire [LARGURA-1:0]  endereco_debug,
    output wire [LARGURA-1:0]  dado_debug
);

    localparam BITS_END = $clog2(PROFUNDIDADE);

    reg [LARGURA-1:0] memoria [0:PROFUNDIDADE-1];

    // endereco em bytes -> indice de palavra (descarta os 2 bits de baixo)
    wire [BITS_END-1:0] indice = endereco[BITS_END+1:2];

    integer i;
    initial begin
        for (i = 0; i < PROFUNDIDADE; i = i + 1)
            memoria[i] = {LARGURA{1'b0}};
    end

    assign dado_leitura = memoria[indice];
    assign dado_debug   = memoria[endereco_debug[BITS_END+1:2]];

    always @(posedge clk) begin
        if (escreve_mem)
            memoria[indice] <= dado_escrita;
    end

endmodule
