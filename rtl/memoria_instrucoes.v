// ============================================================================
//  memoria_instrucoes — onde o programa mora
//
//  OBJETIVO
//  Receber o endereco vindo do PC e devolver a instrucao de 32 bits que esta
//  naquela posicao.
//
//  E UMA ROM: so leitura. O processador nunca escreve no proprio programa.
//  Por isso nao tem clock nem sinal de escrita — e combinacional, como o
//  extensor de sinal.
//
//  DE ONDE VEM O CONTEUDO
//  Do arquivo gerado pelo nosso montador:
//      mem/programa.asm --[tools/assembler.py]--> mem/programa.txt
//  Uma palavra binaria de 32 bits por linha, que e o formato que $readmemb
//  entende. (O mem/programa.mif, com o mesmo conteudo, e para a IP de memoria
//  do Quartus na hora da sintese.)
//
//  ENDERECO EM BYTES x INDICE EM PALAVRAS
//  O PC conta em BYTES: 0, 4, 8, 12...  O array e indexado em PALAVRAS:
//  0, 1, 2, 3...  A conversao e dividir por 4, que em binario e descartar os
//  dois bits de baixo — o que o recorte [BITS_END+1:2] faz.
//
//      PC = 12  ->  1100 em binario  ->  descarta "00"  ->  11 = palavra 3
//
//  Os dois bits descartados sao sempre zero porque toda instrucao esta
//  alinhada em 4 bytes. E a mesma razao de o campo do "j" guardar o endereco
//  dividido por 4.
// ============================================================================
`timescale 1ns/1ps

module memoria_instrucoes #(
    parameter LARGURA      = 32,
    parameter PROFUNDIDADE = 256,
    parameter ARQUIVO      = "mem/programa.txt"
)(
    input  wire [LARGURA-1:0] endereco,    // vem do PC, em bytes
    output wire [LARGURA-1:0] instrucao
);

    localparam BITS_END = $clog2(PROFUNDIDADE);

    reg [LARGURA-1:0] memoria [0:PROFUNDIDADE-1];

    initial $readmemb(ARQUIVO, memoria);

    assign instrucao = memoria[endereco[BITS_END+1:2]];

    // ATENCAO: $readmemb preenche apenas as linhas que existem no arquivo
    // (63 instrucoes). O resto do array fica em 'x' na simulacao, NAO em zero.
    // Se o PC passar do fim do programa, a instrucao vira 'xxxx...' e o x se
    // espalha por todo o datapath. O "j end" no fim do programa.asm existe
    // para que isso nunca aconteca. O aviso do Icarus
    //     "Not enough words in the file for the requested range"
    // e esperado e nao indica erro.

endmodule
