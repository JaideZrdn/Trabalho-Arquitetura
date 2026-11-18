// ============================================================================
//  de2_115_top_pipeline — involucro de placa para a DE2-115, versao pipeline
//
//  Mesma ideia do de2_115_top da 2a entrega: o processador (mips_pipeline)
//  nao sabe que existe uma placa, e este modulo e a unica peca que conhece
//  chaves, botoes, LEDs e displays. Os dois involucros convivem no
//  repositorio; o projeto do Quartus escolhe qual e a entidade de topo.
//
//  O QUE MUDOU EM RELACAO AO INVOLUCRO DO MONOCICLO
//
//  1. Deteccao de fim. No monociclo bastava ver o PC parar, porque o `j end`
//     aponta para si mesmo e o PC fica constante. No pipeline isso nao
//     funciona: o salto e resolvido no estagio EX, entao duas instrucoes
//     adiante do laco sao buscadas e descartadas a cada volta, e o PC circula
//     entre tres enderecos para sempre. Pior, o PC PASSA pelo endereco do
//     laco bem no comeco da execucao, de forma especulativa, enquanto o
//     `jal sort` ainda esta em voo.
//     O criterio aqui e outro: o programa terminou quando passa CICLOS_SILENCIO
//     ciclos sem nenhuma escrita em registrador nem em memoria. E o mesmo
//     criterio do testbench do processador.
//
//  2. Velocidade. O monociclo gasta 406 ciclos e rodava a 1 Hz, uns 6min46.
//     O pipeline gasta 563 ciclos — mais ciclos, cada um mais curto. Para a
//     demonstracao durar o mesmo tempo, o clock aqui e 563/406 = 1,387 vezes
//     mais rapido: 1,387 Hz. Da os mesmos 6min46.
//     SW[15] liga um modo 8 vezes mais rapido, que termina em ~51 s.
//
//  3. LEDs de perigo. O pipeline tem tres situacoes que o monociclo nao tem,
//     e as tres aparecem em LEDs verdes. No modo passo-a-passo da para ver o
//     LED de stall acender exatamente nas duas instrucoes do programa que
//     sofrem load-use.
//
//  4. PC com 12 bits nos displays. No pipeline o PC chega a 0x100, porque a
//     busca especulativa passa do fim do programa. Oito bits truncariam isso
//     para 0x00. HEX5, que estava apagado no involucro do monociclo, agora
//     carrega o digito mais alto.
//
//  CONTROLES
//      KEY[0]      reset (ativo em nivel baixo: apertado = reset)
//      KEY[1]      avanca UM ciclo de clock, quando em modo passo-a-passo
//      SW[17]      0 = clock automatico | 1 = passo-a-passo
//      SW[16]      0 = HEX3..HEX0 mostram v[i] | 1 = mostram o contador de ciclos
//      SW[15]      0 = 1,387 Hz (~6min46, igual a 2a entrega) | 1 = ~11 Hz (~51 s)
//      SW[2:0]     qual posicao do vetor mostrar: v[0] a v[7]
//
//  MOSTRADORES
//      HEX3..HEX0  v[i] em hexadecimal, ou o contador de ciclos (SW[16])
//      HEX4        o indice i selecionado
//      HEX7..HEX5  PC atual, em hexadecimal, 12 bits
//      LEDR[7:0]   PC[7:0] em binario — da para ver o programa andando
//      LEDR[17]    aceso enquanto o processador esta em reset
//      LEDG[0]     aceso quando o programa chegou ao fim
//      LEDG[1]     stall de load-use NESTE ciclo
//      LEDG[2]     desvio tomado ou salto NESTE ciclo (duas instrucoes descartadas)
//      LEDG[3]     encaminhamento ativo NESTE ciclo
//      LEDG[8]     pisca junto com o clock do processador
//
//  COMO DEMONSTRAR
//      1. SW[17]=0, SW[15]=1, SW[16]=0. Aperta e solta KEY[0]. Em ~51 s o
//         programa roda inteiro; girando SW[2:0] da para ver o vetor sendo
//         ordenado ao vivo. Quando LEDG[0] acende, SW[2:0] de 000 a 111
//         mostra 1 2 3 4 5 7 8 9.
//      2. SW[16]=1 no fim: HEX3..HEX0 mostram 0x233 = 563 ciclos. E o numero
//         que vale comparar com os 406 do monociclo.
//      3. SW[17]=1 e cada aperto de KEY[1] avanca um ciclo. LEDG[2] acende
//         nos desvios, LEDG[3] nos encaminhamentos, LEDG[1] nos dois stalls.
//
//  NOTA DE PROJETO: o clock do processador e derivado e selecionado por
//  multiplexador, igual ao involucro do monociclo. Em projeto industrial isso
//  se faz com habilitacao de clock; a ~1 Hz, para demonstracao, a
//  simplificacao e segura e esta registrada aqui de proposito.
// ============================================================================
`timescale 1ns/1ps

module de2_115_top_pipeline #(
    // caminho relativo AO DIRETORIO DO PROJETO QUARTUS. Com o .qpf em
    // quartus/, o programa fica um nivel acima.
    parameter ARQUIVO_PROGRAMA  = "../mem/programa.txt",
    // 50 MHz / (2 * 18_030_000) = 1,387 Hz. 563 ciclos levam 406 s, os mesmos
    // 6min46 que os 406 ciclos do monociclo levavam a 1 Hz.
    parameter DIVISOR_LENTO     = 18_030_000,
    parameter DIVISOR_RAPIDO    = 2_253_750,   // 8x mais rapido: ~51 s
    parameter ESPERA_BOTAO      = 500_000,     // 10 ms de filtro
    parameter CICLOS_SILENCIO   = 20           // ciclos sem escrita = terminou
)(
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [17:0] SW,
    output wire [17:0] LEDR,
    output wire [8:0]  LEDG,
    output wire [6:0]  HEX0, HEX1, HEX2, HEX3,
    output wire [6:0]  HEX4, HEX5, HEX6, HEX7
);

    wire reset = ~KEY[0];              // KEY e ativo em nivel baixo

    // ---- clock do processador ----------------------------------------------
    wire clk_lento, clk_rapido, pulso_passo;

    divisor_clock #(.DIVISOR(DIVISOR_LENTO)) divisor_l (
        .clk_in(CLOCK_50), .reset(reset), .clk_out(clk_lento)
    );

    divisor_clock #(.DIVISOR(DIVISOR_RAPIDO)) divisor_r (
        .clk_in(CLOCK_50), .reset(reset), .clk_out(clk_rapido)
    );

    botao_pulso #(.ESPERA(ESPERA_BOTAO)) passo (
        .clk(CLOCK_50), .reset(reset), .botao_n(KEY[1]), .pulso(pulso_passo)
    );

    wire clk_auto = SW[15] ? clk_rapido : clk_lento;
    wire clk_cpu  = SW[17] ? pulso_passo : clk_auto;

    // ---- o processador ------------------------------------------------------
    wire [31:0] endereco_debug = {27'd0, SW[2:0], 2'b00};   // i * 4
    wire [31:0] dado_debug, pc_debug, instrucao_debug;
    wire        escreveu, stall, flush, forward;

    mips_pipeline #(
        .LARGURA(32), .PROF_INSTRUCOES(256), .PROF_DADOS(256),
        .ARQUIVO_PROGRAMA(ARQUIVO_PROGRAMA)
    ) cpu (
        .clk(clk_cpu), .reset(reset),
        .endereco_debug(endereco_debug), .dado_debug(dado_debug),
        .pc_debug(pc_debug), .instrucao_debug(instrucao_debug),
        .escreveu_debug(escreveu), .stall_debug(stall),
        .flush_debug(flush), .forward_debug(forward)
    );

    // ---- deteccao de fim: CICLOS_SILENCIO ciclos sem escrita nenhuma -------
    //
    //  Ver a nota 1 no cabecalho. O contador zera a cada escrita e, quando
    //  satura, trava `parado` em 1 — so o reset limpa.
    reg [7:0] silencio;
    reg       parado;

    always @(posedge clk_cpu or posedge reset) begin
        if (reset) begin
            silencio <= 8'd0;
            parado   <= 1'b0;
        end else if (escreveu) begin
            silencio <= 8'd0;
        end else if (silencio == CICLOS_SILENCIO - 1) begin
            parado   <= 1'b1;
        end else begin
            silencio <= silencio + 8'd1;
        end
    end

    // ---- contador de ciclos -------------------------------------------------
    //
    //  Conta so enquanto o programa corre, e desconta a janela de silencio,
    //  para mostrar exatamente os 563 ciclos uteis.
    reg [15:0] ciclos;

    always @(posedge clk_cpu or posedge reset) begin
        if (reset)        ciclos <= 16'd0;
        else if (!parado) ciclos <= ciclos + 16'd1;
    end

    wire [15:0] ciclos_uteis = parado ? (ciclos - CICLOS_SILENCIO) : ciclos;

    // ---- displays -----------------------------------------------------------
    wire [15:0] valor = SW[16] ? ciclos_uteis : dado_debug[15:0];

    decodificador_7seg d0 (.digito(valor[3:0]),       .segmentos(HEX0));
    decodificador_7seg d1 (.digito(valor[7:4]),       .segmentos(HEX1));
    decodificador_7seg d2 (.digito(valor[11:8]),      .segmentos(HEX2));
    decodificador_7seg d3 (.digito(valor[15:12]),     .segmentos(HEX3));

    decodificador_7seg d4 (.digito({1'b0, SW[2:0]}),  .segmentos(HEX4));

    decodificador_7seg d5 (.digito(pc_debug[11:8]),   .segmentos(HEX5));
    decodificador_7seg d6 (.digito(pc_debug[3:0]),    .segmentos(HEX6));
    decodificador_7seg d7 (.digito(pc_debug[7:4]),    .segmentos(HEX7));

    // ---- LEDs ---------------------------------------------------------------
    assign LEDR = {reset, 9'd0, pc_debug[7:0]};
    assign LEDG = {clk_cpu, 4'd0, forward, flush, stall, parado};

endmodule
