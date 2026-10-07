// ============================================================================
//  de2_115_top — invólucro de placa para a DE2-115
//
//  O processador (mips_monociclo) nao sabe que existe uma DE2-115, e isso e
//  proposital: ele tem apenas clk, reset e as portas de observacao. Este
//  modulo e a unica peca que conhece chaves, botoes, LEDs e displays.
//
//  CONTROLES
//      KEY[0]      reset (ativo em nivel baixo: apertado = reset)
//      KEY[1]      avanca UMA instrucao, quando em modo passo-a-passo
//      SW[17]      0 = clock automatico lento | 1 = passo-a-passo
//      SW[2:0]     qual posicao do vetor mostrar: v[0] a v[7]
//
//  MOSTRADORES
//      HEX3..HEX0  valor de v[i], em hexadecimal
//      HEX4        o indice i selecionado
//      HEX5        apagado
//      HEX7..HEX6  PC atual, em hexadecimal (vai ate 0xF8 = 248)
//      LEDR[7:0]   PC, em binario — da para ver o programa andando
//      LEDG[0]     aceso quando o programa chegou ao fim (PC parado)
//      LEDG[8]     pisca junto com o clock do processador
//
//  DEMONSTRACAO
//      1. SW[17] = 0, aperta e solta KEY[0]: o programa roda em ~7 minutos a
//         1 Hz. Girando SW[2:0] da para ver o vetor sendo ordenado ao vivo.
//      2. SW[17] = 1: cada aperto de KEY[1] avanca uma instrucao, e o PC nos
//         LEDs mostra o beq voltando e o jal saltando.
//
//  NOTA DE PROJETO: o clock do processador e derivado (dividido ou gerado por
//  botao) e selecionado por um multiplexador. Em projeto industrial isso se
//  faz com habilitacao de clock, nao com multiplexador de clock; a 1 Hz, para
//  demonstracao, a simplificacao e segura e esta registrada aqui de proposito.
// ============================================================================
`timescale 1ns/1ps

module de2_115_top #(
    // caminho relativo AO DIRETORIO DO PROJETO QUARTUS. Com o .qpf em
    // quartus/, o programa fica um nivel acima.
    parameter ARQUIVO_PROGRAMA = "../mem/programa.txt",
    parameter DIVISOR          = 25_000_000,   // 50 MHz -> 1 Hz
    parameter ESPERA_BOTAO     = 500_000       // 10 ms de filtro
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

    // ---- clock do processador ---------------------------------------------
    wire clk_lento, pulso_passo;

    divisor_clock #(.DIVISOR(DIVISOR)) divisor (
        .clk_in(CLOCK_50), .reset(reset), .clk_out(clk_lento)
    );

    botao_pulso #(.ESPERA(ESPERA_BOTAO)) passo (
        .clk(CLOCK_50), .reset(reset), .botao_n(KEY[1]), .pulso(pulso_passo)
    );

    wire clk_cpu = SW[17] ? pulso_passo : clk_lento;

    // ---- o processador ------------------------------------------------------
    wire [31:0] endereco_debug = {27'd0, SW[2:0], 2'b00};   // i * 4
    wire [31:0] dado_debug, pc_debug, instrucao_debug;

    mips_monociclo #(
        .LARGURA(32), .PROF_INSTRUCOES(256), .PROF_DADOS(256),
        .ARQUIVO_PROGRAMA(ARQUIVO_PROGRAMA)
    ) cpu (
        .clk(clk_cpu), .reset(reset),
        .endereco_debug(endereco_debug), .dado_debug(dado_debug),
        .pc_debug(pc_debug), .instrucao_debug(instrucao_debug)
    );

    // ---- deteccao de fim: o `j end` faz o PC apontar para si mesmo ---------
    reg [31:0] pc_anterior;
    reg        parado;
    always @(posedge clk_cpu or posedge reset) begin
        if (reset) begin
            pc_anterior <= 32'hFFFF_FFFF;
            parado      <= 1'b0;
        end else begin
            pc_anterior <= pc_debug;
            if (pc_debug == pc_anterior) parado <= 1'b1;
        end
    end

    // ---- displays -----------------------------------------------------------
    decodificador_7seg d0 (.digito(dado_debug[3:0]),   .segmentos(HEX0));
    decodificador_7seg d1 (.digito(dado_debug[7:4]),   .segmentos(HEX1));
    decodificador_7seg d2 (.digito(dado_debug[11:8]),  .segmentos(HEX2));
    decodificador_7seg d3 (.digito(dado_debug[15:12]), .segmentos(HEX3));

    decodificador_7seg d4 (.digito({1'b0, SW[2:0]}),   .segmentos(HEX4));

    assign HEX5 = 7'b1111111;          // apagado

    decodificador_7seg d6 (.digito(pc_debug[3:0]),     .segmentos(HEX6));
    decodificador_7seg d7 (.digito(pc_debug[7:4]),     .segmentos(HEX7));

    // ---- LEDs ---------------------------------------------------------------
    assign LEDR = {10'd0, pc_debug[7:0]};
    assign LEDG = {clk_cpu, 7'd0, parado};

endmodule
